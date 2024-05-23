;---------------
; Assembly Code
;---------------
#define __SFR_OFFSET 0x00
#include "avr/io.h"
;------------------------
.global main

main:
  RCALL DHT11_sensor
  RJMP main

;================================================================
LCD_write:
      LDI   R16, 0xFF
      OUT   DDRD, R16         ;set port D o/p for data
      OUT   DDRB, R16         ;set port B o/p for command
      CBI   PORTB, 0          ;EN = 0
      RCALL delay_ms          ;wait for LCD power on
      ;-----------------------------------------------------
      RCALL LCD_init          ;subroutine to initialize LCD
      ;-----------------------------------------------------
again:RCALL disp_message      ;subroutine to display message
      ;-----------------------------------------------------
      RCALL command_wrt       ;send command code
      RCALL delay_ms
      ;-----------------------------------------------------
      LDI   R17, 4            ;wait 1 second
l1:   RCALL delay_seconds
      DEC   R17
      BRNE  l1
      ;-----------------------------------------------------
      RJMP  agn
;================================================================
LCD_init:
      LDI   R16, 0x33         ;init LCD for 4-bit data
      RCALL command_wrt       ;send to command register
      RCALL delay_ms
      LDI   R16, 0x32         ;init LCD for 4-bit data
      RCALL command_wrt
      RCALL delay_ms
      LDI   R16, 0x28         ;LCD 2 lines, 5x7 matrix
      RCALL command_wrt
      RCALL delay_ms
      LDI   R16, 0x0C         ;disp ON, cursor OFF
      RCALL command_wrt
      LDI   R16, 0x01         ;clear LCD
      RCALL command_wrt
      RCALL delay_ms
      LDI   R16, 0x06         ;shift cursor right
      RCALL command_wrt
      RET  
;================================================================
command_wrt:
      MOV   R27, R16
      ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
      OUT   PORTD, R27        ;o/p high nibble to port D
      CBI   PORTB, 2          ;RS = 0 for command
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;widen EN pulse
      CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
      RCALL delay_us          ;delay in micro seconds
      ;----------------------------------------------------
      MOV   R27, R16
      SWAP  R27               ;swap nibbles
      ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
      OUT   PORTD, R27        ;o/p high nibble to port D
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;widen EN pulse
      CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
      RCALL delay_us          ;delay in micro seconds
      RET
;================================================================
data_wrt:
      MOV   R27, R16
      ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
      OUT   PORTD, R27        ;o/p high nibble to port D
      SBI   PORTB, 2          ;RS = 1 for data
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;make wide EN pulse
      CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
      RCALL delay_us          ;delay in micro seconds
      ;----------------------------------------------------
      MOV   R27, R16
      SWAP  R27               ;swap nibbles
      ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
      OUT   PORTD, R27        ;o/p high nibble to port D
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;widen EN pulse
      CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
      RCALL delay_us          ;delay in micro seconds
      RET
;================================================================
disp_message:
      MOV   R16, R18
      RCALL ASCII_MSD         ;convert R16 bagian MSD ke ASCII
      RCALL data_wrt          ;via data register
      RCALL delay_seconds
      ;----------------
      RCALL ASCII_LSD         ;convert R16 bagian LSD ke ASCII
      RCALL data_wrt
      RCALL delay_seconds
      ;----------------
      LDI   R16, 0xC0         ;cursor beginning of 2nd line
      RCALL command_wrt
      RCALL delay_ms
      ;----------------
      LDI   R17, 17           ;wait 3 seconds
l2:   RCALL delay_seconds
      DEC   R17
      BRNE  l2
      RET
;================================================================
delay_short:
      NOP
      NOP
      RET
;------------------------
delay_us:
      LDI   R20, 90
l3:   RCALL delay_short
      DEC   R20
      BRNE  l3
      RET
;-----------------------
delay_ms:
      LDI   R21, 40
l4:   RCALL delay_us
      DEC   R21
      BRNE  l4
      RET
;================================================================
delay_seconds:        ;nested loop subroutine (max delay 3.11s)
    LDI   R20, 20    ;outer loop counter 
l5: LDI   R21, 20    ;mid loop counter
l6: LDI   R22, 20     ;inner loop counter to give 0.25s delay
l7: DEC   R22         ;decrement inner loop
    BRNE  l7          ;loop if not zero
    DEC   R21         ;decrement mid loop
    BRNE  l6          ;loop if not zero
    DEC   R20         ;decrement outer loop
    BRNE  l5          ;loop if not zero
    RET               ;return to caller
;----------------------------------------------------------------


DHT11_sensor:
;------------
    LDI   R17, 0xFF
;-----------------------------------------------------------------
agn:RCALL delay_2s      ;wait 2s for DHT11 to get ready
;-----------------------------------------------------------------
;start_signal
;------------
    SBI   DDRB, 1       ;pin PB0 as o/p
    CBI   PORTB, 1      ;first, send low pulse
    RCALL delay_20ms    ;for 20ms
    SBI   PORTB, 1      ;then send high pulse
;-----------------------------------------------------------------
;responce signal
;---------------
    CBI   DDRB, 1       ;pin PB0 as i/p
w1: SBIC  PINB, 1
    RJMP  w1            ;wait for DHT11 low pulse
w2: SBIS  PINB, 1
    RJMP  w2            ;wait for DHT11 high pulse
w3: SBIC  PINB, 1
    RJMP  w3            ;wait for DHT11 low pulse
;-----------------------------------------------------------------
    RCALL DHT11_reading ;read humidity (1st byte of 40-bit data)
    RCALL DHT11_reading
    RCALL DHT11_reading ;read temp (3rd byte of 40-bit data)
;Bacaan tempratur di R18 terus sekarang kita pindah ke LCD_write buat nampilinnya
    RCALL LCD_write
    RJMP  agn           ;go back & get another sensor reading
;=================================================================
DHT11_reading:
    LDI   R17, 8        ;set counter for receiving 8 bits
    CLR   R18           ;clear data register
    ;-------------------------------------------------------
w4: SBIS  PINB, 1
    RJMP  w4            ;detect data bit (high pulse)
    RCALL delay_timer0  ;wait 50us & then check bit value
    ;-------------------------------------------------------
    SBIS  PINB, 1       ;if received bit=1, skip next inst
    RJMP  skp           ;else, received bit=0, jump to skp
    SEC                 ;set carry flag (C=1)
    ROL   R18           ;shift in 1 into LSB data register
    RJMP  w5            ;jump & wait for low pulse
skp:LSL   R18           ;shift in 0 into LSB data register
    ;-------------------------------------------------------
w5: SBIC  PINB, 1
    RJMP  w5            ;wait for DHT11 low pulse
    ;-------------------------------------------------------
    DEC   R17           ;decrement counter
    BRNE  w4            ;go back & detect next bit
    RET                 ;return to calling subroutine
;=================================================================
;delay subroutines
;=================================================================
delay_20ms:             ;delay 20ms
    LDI   R21, 255
m3: LDI   R22, 210
m4: LDI   R23, 2
m5: DEC   R23
    BRNE  m5
    DEC   R22
    BRNE  m4
    DEC   R21
    BRNE  m3
    RET
;-----------------------------------------------------------------
delay_2s:               ;delay 2s
    LDI   R21, 255
m6: LDI   R22, 255
m7: LDI   R23, 164
m8: DEC   R23
    BRNE  m8
    DEC   R22
    BRNE  m7
    DEC   R21
    BRNE  m6
    RET
;===============================================================
delay_timer0:             ;50 usec delay via Timer 0
    ;---------------------------------------------------------
    CLR   R20
    OUT   TCNT0, R20      ;initialize timer0 with count=0
    LDI   R20, 100
    OUT   OCR0A, R20      ;OCR0 = 100
    LDI   R20, 0b00001010
    OUT   TCCR0B, R20     ;timer0: CTC mode, prescaler 8
    ;---------------------------------------------------------
m2: IN    R20, TIFR0      ;get TIFR0 byte & check
    SBRS  R20, OCF0A      ;if OCF0=1, skip next instruction
    RJMP  m2              ;else, loop back & check OCF0 flag
    ;---------------------------------------------------------
    CLR   R20
    OUT   TCCR0B, R20     ;stop timer0
    ;---------------------------------------------------------
    LDI   R20, (1<<OCF0A)
    OUT   TIFR0, R20      ;clear OCF0 flag
    RET

ASCII_MSD:
    MOV   R23, R16      ;save copy of result
    ANDI  R16, 0xF0     ;extract & swap high-nibble
    SWAP  R16 
    SUBI  R16, -48      ;R16 = R16 - (48) = R16 + 48
    MOV   R28, R16      ;save a copy of high-byte result
    SUBI  R28, 58       ;if +ve       
    BRPL  A_F_D1        ;branch & add 7 to get ASCII A to F
n1: RET
;========================================================================
ASCII_LSD:
    MOV   R16, R23      ;restore copy of result
    ANDI  R16, 0x0F     ;extract low-nibble
    SUBI  R16, -48      ;R16 = R16 - (48) = R16 + 48
    MOV   R28, R16      ;save a copy of high-byte result
    SUBI  R28, 58       ;if +ve
    BRPL  A_F_D0        ;branch & add 7 to get ASCII A to F
n2: RET    
;====================================================================
A_F_D1:
    SUBI  R16, -7       ;R16 = R16 - (7) = R16 + 7
    RJMP  n1
;---------------------------------------------------------------
A_F_D0:
    SUBI  R16, -7       ;R16 = R16 - (7) = R16 + 7
    RJMP  n2
;---------------------------------------------------------------



