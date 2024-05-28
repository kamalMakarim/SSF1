;================================================;
; Assembly Code for AC Automation
; By Kelompok 1 SSF
;--------------------------------
; Dimas Dermawan | Kamal Makarim 
; M. Jibril A.   | A. Zaidan L.
;================================================;


#define __SFR_OFFSET 0x00
#include "avr/io.h"


.global main


;=======================================;
;           CONSTANT Variables          ;
;=======================================;
.equ    CMD,  0x00
.equ    DATA, 0x01


;=======================================;
;   Configuration and Register Labels   ;
;=======================================;
; Registers:
;-----------------LCD-------------------;
;     R20 = LED CMD/DATA MODE
;     R16 = DATA TO BE SENT TO LCD
;     R18 = PROCESSED VALUE ON FUNCTIONS
;------------------I2C------------------;
;     R21 = CONFIGURATIONS
;     R24 = DATA TO BE SENT WITH I2C
;-----------------DHT11-----------------;
;     R26 = HUMIDITY
;     R28 = TEMPERATURE
;-----------------Motor-----------------;
;     R30 = FAN SPEED
;---------------------------------------;


;==============================================================
main:
    RCALL   LCD_Initialize      ;Initialize LCD before using
    ;---------------------------;
    LDI     R16, 0xFF
    OUT     DDRB, R16
    ;---------------------------;
    SBI     DDRB, 3
    SBI     DDRB, 4
    CBI     DDRD, 2
    ;---------------------------;
    LDI     R23, (1<<INT0)      ;Set to Use INT0
    OUT     EIMSK, R23          ;Enable INT0 interrupt
    ;---------------------------;
    LDI     R23, (1<<ISC01)     ;Falling edge triggers interrupt
    STS     EICRA, R23
    SEI                         ;SET Interrupt
    ;---------------------------;
    CBI     PORTB, 3            ;PINB 5 As Interrupt Output
    RCALL   delay_ms
    ;---------------------------;
    Check_Interrupt:
        SBIC  PINB, 3
        RJMP  Start_Program
        RJMP  Check_Interrupt
;==============================================================
Start_Program:
    ;---------------------------;
    LDI     R16, 0x0C           ;0x0C Command to turn ON LCD
    RCALL   LCD_Write_Command   ;
    ;---------------------------;
    RCALL LCD_Welcome
    ;---------------------------;
    RJMP  DHT11_Sensor
    ;---------------------------;
;==============================================================


;==============================================================
Set_Fan_Speed:
    CPI     R28, 18
    ;BRLO    R
    LDI     R30, 255
    RCALL   Set_Motor_DC
;==============================================================
Set_Motor_DC:
    LDI   R31, 10               ;count to give enough cycles of PWM
    ;---------------------------;
    md2:SBI   PORTB, 4
        RCALL delay_motor
        CBI   PORTB, 4          ;send msec pulse
        RCALL delay_20ms        ;wait 20ms before re-sending pulse
        DEC   R31
        BRNE  md2                ;go back & repeat PWM signal
    ;---------------------------;
    bak:RCALL delay_ms          ;0.5s delay
        RET                     ;& return to main subroutine
;==============================================================
Fan_Speed_Hot:


;=============================================================;
;                      DHT11 FUNCTIONS                        ;
;=============================================================;
DHT11_Sensor:
    LDI   R30, 0xFF
    ;-----------------------;
    read:
        SBIS  PINB, 3
        RJMP  LCD_Turn_Off
        RCALL delay_2s      ;wait 2s for DHT11 to get ready
    ;-----------------------;
    ; Start Signal
    ;-----------------------;
        SBI   DDRB, 1       ;pin PB0 as o/p
        CBI   PORTB, 1      ;first, send low pulse
        RCALL delay_20ms    ;for 20ms
        SBI   PORTB, 1      ;then send high pulse
    ;-----------------------;
    ; Response Signal
    ;-----------------------;
        CBI   DDRB, 1       ;pin PB0 as i/p
    w1: SBIC  PINB, 1
        RJMP  w1            ;wait for DHT11 low pulse
    w2: SBIS  PINB, 1
        RJMP  w2            ;wait for DHT11 high pulse
    w3: SBIC  PINB, 1
        RJMP  w3            ;wait for DHT11 low pulse
    ;-----------------------;
    ; Reading Output
    ;-----------------------;
    RCALL DHT11_reading     ;read humidity (1st byte of 40-bit data)
    MOV   R26, R18          ;copy humidity
    ;-----------------------;
    RCALL DHT11_reading     ;skip humidity floating value
    ;-----------------------;
    RCALL DHT11_reading     ;read temp (3rd byte of 40-bit data)
    MOV   R28, R18          ;copy temperature
    ;-----------------------;
    ;RCALL Set_Fan_Speed
    RCALL LCD_Display_Reading ;print value
    RJMP  read              ;go back & get another sensor reading
;==============================================================
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
;=============================================================


;=============================================================;
;                       I2C FUNCTIONS                         ;
;=============================================================;
I2C_Init:
    LDI   R21, 0
    STS   TWSR, R21       ;prescaler = 0
    ;---------------------;
    LDI   R21, 72
    STS   TWBR, R21       ;SCK freq = 100kHz
    ;---------------------;
    LDI   R21, (1<<TWEN)
    STS   TWCR, R21       ;enable TWI
    ;---------------------;
    RET
;==============================================================
I2C_Start:
    LDI   R21, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
    STS   TWCR, R21           ;transmit START condition
    ;-------------------------;
    wt1:LDS   R21, TWCR
        SBRS  R21, TWINT      ;TWI interrupt = 1?
        RJMP  wt1             ;no, wait for end of transmission
        ;---------------------;
        RET
;==============================================================
I2C_Write:
    STS   TWDR, R24                   ;copy byte in R24 into data register
    LDI   R21, (1<<TWINT)|(1<<TWEN)
    STS   TWCR, R21                   ;transmit byte
    ;---------------------------------;
    wt2:LDS   R21, TWCR
        SBRS  R21, TWINT
        RJMP  wt2                     ;wait for end of transmission
        ;-----------------------------;
        RET
;==============================================================
I2C_Stop:
    LDI   R21, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
    STS   TWCR, R21       ;transmit STOP condition
    RET
;==============================================================
;------ Function to Start The I2C Signaling Process
I2C_Send_Byte:;
    RCALL   I2C_Start   ;Start I2C Protocol
    ;------------------------------------------
    LDI     R24, 0x40   ;LOAD The PCF8574 Component Address
    RCALL   I2C_Write   ;Write The Address
    ;------------------------------------------
    MOV     R24, R18    ;LOAD Processed Data From Previous Functions
    RCALL   I2C_Write   ;Send The Processed Data
    ;------------------------------------------
    RCALL   I2C_Stop    ;Stop The Protocol
    ;------------------------------------------
    RET
;==============================================================


;=============================================================;
;                       LCD FUNCTIONS                         ;
;=============================================================;
;------ LCD Configuration Initializations
LCD_Initialize:
    ;-----------------------------;
    LDI     R16, 0x33             ;0x33 Command for LCD to receive 4-bit data
    RCALL   LCD_Write_Command     ;Write The Command
    ;-----------------------------;
    LDI     R16, 0x32             ;
    RCALL   LCD_Write_Command     ;
    ;-----------------------------;
    LDI     R16, 0x28             ;0x28 Command for LCD to 
    RCALL   LCD_Write_Command     ;
    ;-----------------------------;
    LDI     R16, 0x0C             ;0x0C Command to turn ON LCD
    RCALL   LCD_Write_Command     ;
    ;-----------------------------;
    LDI     R16, 0x01             ;0x01 Command to clear
    RCALL   LCD_Write_Command     ;
    ;-----------------------------;
    LDI     R16, 0x06             ;0x06 Command to set shift
    RCALL   LCD_Write_Command     ;     LCD cursor to right
    ;-----------------------------;
    RET
;==============================================================
;------ Function to Write Character into LCD
LCD_Write_Char:
    MOV     R18, R16              ;Copy data to be sent to R18
    ANDI    R18, 0xF0             ;AND to get high nibble
    OR      R18, R20              ;OR with mode (high | mode)
    RCALL   LCD_Send_4_Bit        ;Send the first 4 high bits to LCD
    ;------------------------------------------
    MOV     R18, R16              ;Copy data again
    SWAP    R18                   ;SWAP to placed the correct format
    ANDI    R18, 0xF0             ;AND to get the low nibble
    OR      R18, R20              ;OR with mode (low  | mode)
    RCALL   LCD_Send_4_Bit        ;Send the last 4 low bits to LCD
    ;------------------------------------------
    RET
;==============================================================
;------ Function to Send Formatted Byte Using I2C
LCD_Send_4_Bit:
    RCALL   I2C_Send_Byte          ;Send Raw Value
    ;------------------------------------------
    ORI     R18, 0b00000100        ;OR to SET The Enable Bit
    RCALL   I2C_Send_Byte          ;Send Write Signal Using I2C
    RCALL   delay_short            ;Delay to wait for processing                
    ;------------------------------------------
    ANDI    R18, 0b11111011        ;AND to RESET The Data Byte
    RCALL   I2C_Send_Byte          ;Send RESET Signal Using I2C
    RCALL   delay_us               ;
    ;------------------------------------------
    RET
;==============================================================
;------ Function to Send LCD Command
LCD_Write_Command:
    LDI     R20, CMD           ;set data mode
    RCALL   LCD_Write_Char     ;
    RCALL   delay_ms           ;
    RET
;==============================================================
;------ Function to Send LCD Data
LCD_Write_Data:
    LDI     R20, DATA          ;set data mode
    RCALL   LCD_Write_Char     ;
    RCALL   delay_ms           ;
    RET
;==============================================================
LCD_Turn_Off:
    ;---------------------------;
    LDI     R16, 0x01
    RCALL   LCD_Write_Command
    ;---------------------------;
    LDI     R16, 0x08
    RCALL   LCD_Write_Command
    ;---------------------------;
    RJMP    Check_Interrupt
;==============================================================
LCD_Display_Reading:
    ;---------------------------;
    LDI     R16, 0x01           ; Clear LCD
    RCALL   LCD_Write_Command   ; Write Command
    ;---------------------------;
    LDI     R16, 0x06           ; Shift LCD Cursor to Right
    RCALL   LCD_Write_Command   ;
    ;---------------------------;
    RCALL   LCD_Temperature_Message
    ;---------------------------;
    MOV     R16, R28            ; Get Temperature Data
    RCALL   LCD_Display_Number  ;
    RCALL   MSG_Derajat         ;
    ;---------------------------;
    LDI     R16, 0xC0           ; Begin second line
    RCALL   LCD_Write_Command   ;
    ;---------------------------;
    RCALL   LCD_Humidity_Message;
    ;---------------------------;
    MOV     R16, R26            ; Get Humidity Data
    RCALL   LCD_Display_Number  ;
    LDI     R16, '%'            ; Display Percentage Char
    RCALL   LCD_Write_Char      ;
    ;---------------------------;
    RET
;=============================================================
LCD_Display_Number:
    RCALL Binary_To_BCD
    ;---------------------------;
    MOV   R16, R17
    SUBI  R16, -48
    RCALL LCD_Write_Char
    ;---------------------------;
    MOV   R16, R19
    SUBI  R16, -48
    RCALL LCD_Write_Char
    ;---------------------------;
    RET
;=============================================================


;=============================================================;
;                        LCD MESSAGES                         ;
;=============================================================;
LCD_Welcome:
    MSG_Kelompok:
      LDI   R16, 'K'
      RCALL LCD_Write_Data
      LDI   R16, 'e'
      RCALL LCD_Write_Data
      LDI   R16, 'l'
      RCALL LCD_Write_Data
      LDI   R16, 'o'
      RCALL LCD_Write_Data
      LDI   R16, 'm'
      RCALL LCD_Write_Data
      LDI   R16, 'p'
      RCALL LCD_Write_Data
      LDI   R16, 'o'
      RCALL LCD_Write_Data
      LDI   R16, 'k'
      RCALL LCD_Write_Data
      LDI   R16, ' '
      RCALL LCD_Write_Data
      LDI   R16, '1'
      RCALL LCD_Write_Data
    ;-----------------------;
    LDI   R16, 0xC0         ;cursor beginning of 2nd line
    RCALL LCD_Write_Command
    ;-----------------------;
    MSG_Automation:
      LDI   R16, 'A'
      RCALL LCD_Write_Data
      LDI   R16, 'C'
      RCALL LCD_Write_Data
      LDI   R16, ' '
      RCALL LCD_Write_Data
      LDI   R16, 'A'
      RCALL LCD_Write_Data
      LDI   R16, 'u'
      RCALL LCD_Write_Data
      LDI   R16, 't'
      RCALL LCD_Write_Data
      LDI   R16, 'o'
      RCALL LCD_Write_Data
      LDI   R16, 'm'
      RCALL LCD_Write_Data
      LDI   R16, 'a'
      RCALL LCD_Write_Data
      LDI   R16, 't'
      RCALL LCD_Write_Data
      LDI   R16, 'e'
      RCALL LCD_Write_Data
    ;-----------------------;
    RCALL delay_2s
    ;-----------------------;
    LDI   R16, 0x01         ;clear LCD
    RCALL LCD_Write_Command
    ;-----------------------;
    RET
;=============================================================
LCD_Temperature_Message:
    MSG_Suhu:
        LDI     R16, 'S'
        RCALL   LCD_Write_Data
        LDI     R16, 'u'
        RCALL   LCD_Write_Data
        LDI     R16, 'h'
        RCALL   LCD_Write_Data
        LDI     R16, 'u'
        RCALL   LCD_Write_Data
        LDI     R16, ' '
        RCALL   LCD_Write_Data
        LDI     R16, ' '
        RCALL   LCD_Write_Data
        LDI     R16, ':'
        RCALL   LCD_Write_Data
        RET
    ;-----------------------;
    MSG_Derajat:
        LDI     R16, 223
        RCALL   LCD_Write_Data
        LDI     R16, 'C'
        RCALL   LCD_Write_Data
        RET
    ;-----------------------;
;=============================================================
LCD_Humidity_Message:
    MSG_Humid:
        LDI     R16, 'H'
        RCALL   LCD_Write_Data
        LDI     R16, 'u'
        RCALL   LCD_Write_Data
        LDI     R16, 'm'
        RCALL   LCD_Write_Data
        LDI     R16, 'i'
        RCALL   LCD_Write_Data
        LDI     R16, 'd'
        RCALL   LCD_Write_Data
        LDI     R16, ' '
        RCALL   LCD_Write_Data
        LDI     R16, ':'
        RCALL   LCD_Write_Data
        RET
;=============================================================


;=============================================================;
;                      ASCII CONVERTER                        ;
;=============================================================;
Binary_To_BCD:
    CLR   R17                 ; Clear R17 (BCD tens digit)
    CLR   R19                 ; Clear R19 (BCD units digit)
    LDI   R31, 10             ; Load constant 10 for division
    Conversion:
        CP    R16, R31        ; Compare R16 with 10
        BRLO  End_Conversion  ; If R16 < 10, branch to End_Conversion
        SUB   R16, R31        ; Subtract 10 from R16
        INC   R17             ; Increment the tens digit
        RJMP  Conversion      ; Repeat the loop
    End_Conversion:
        MOV   R19, R16        ; Move the remaining units to R19
        RET
;=============================================================
ASCII_MSD:
    MOV   R23, R16      ;save copy of result
    ANDI  R16, 0xF0     ;extract & swap high-nibble
    SWAP  R16
    SUBI  R16, -48      ;R16 = R16 - (48) = R16 + 48
    MOV   R25, R16      ;save a copy of high-byte result
    SUBI  R25, 58       ;if +ve       
    BRPL  A_F_D1        ;branch & add 7 to get ASCII A to F
    n1: RET
;=============================================================
ASCII_LSD:
    MOV   R16, R23      ;restore copy of result
    ANDI  R16, 0x0F     ;extract low-nibble
    SUBI  R16, -48      ;R16 = R16 - (48) = R16 + 48
    MOV   R25, R16      ;save a copy of high-byte result
    SUBI  R25, 58       ;if +ve
    BRPL  A_F_D0        ;branch & add 7 to get ASCII A to F
    n2: RET    
;=============================================================
A_F_D1:
    SUBI  R16, -7       ;R16 = R16 - (7) = R16 + 7
    RJMP  n1
;-------------------------------------------------------------
A_F_D0:
    SUBI  R16, -7       ;R16 = R16 - (7) = R16 + 7
    RJMP  n2
;=============================================================


;=============================================================;
;                      DELAY FUNCTIONS                        ;
;=============================================================;
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
delay_motor:             ;delay via Timer0
    ;-----------------------------------------------------------
    CLR   R21
    OUT   TCNT0, R21      ;initialize timer0 with count=0
    MOV   R21, R30
    OUT   OCR0A, R21
    LDI   R21, 0b00001100
    OUT   TCCR0B, R21     ;timer0: CTC mode, prescaler 256
    ;-----------------------------------------------------------
    dm3:IN    R21, TIFR0      ;get TIFR0 byte & check
        SBRS  R21, OCF0A      ;if OCF0=1, skip next instruction
        RJMP  dm3              ;else, loop back & check OCF0 flag
        ;-----------------------------------------------------------
        CLR   R21
        OUT   TCCR0B, R21     ;stop timer0
        ;-----------------------------------------------------------
        LDI   R21, (1<<OCF0A)
        OUT   TIFR0, R21      ;clear OCF0 flag
        RET
;===============================================================
delay_timer0:           ;50 usec delay via Timer 0
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
;===============================================================
delay_short:
    NOP
    NOP
    RET
;------------------------
delay_us:
    LDI   R30, 90
    dlus: RCALL delay_short
          DEC   R30
          BRNE  dlus
          RET
;-----------------------
delay_ms:
    LDI   R29, 40
    dlms: RCALL delay_us
          DEC   R29
          BRNE  dlms
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
;==============================================================