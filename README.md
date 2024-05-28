--------------------------------------------------------------------------------------------------------------------------------------------------------------------
# PROYEK AKHIR SSF - KELOMPOK 1
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

Achmad Zaidan Lazuardy - 2206059793 <br>
Dimas Dermawan - 2206059654 <br>
Kamal Makarim Iskandar - 2206809841 <br>
Muhammad Jibril Adrian - 2206059660 <br>

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
### i. Introduction to the problem and the solution
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Sebagai salah satu alat yang penting dalam mengatur suhu ruangan, AC menjadi suatu kewajiban dalam sebuah fasilitas umum yang berada di indonesia karena iklim indonesia yang tropis yang membuat suhu dalam ruangan meningkat tentunya AC sangat dibutuhkan untuk mengatur suhu ruangan. Namun, yang menjadi masalah disini adalah, kurang efisiennya pengaturan suhu AC pada ruangan yang terdapat banyak orang, dan kurangnya otomatisasi ketika terjadi perubahan cuaca serta waktu pada pagi ke siang atau siang ke malam.

Solusi yang kami bawa ialah sebuah perangkat controller yang akan digunakan untuk Air Conditioner (AC) yang berbasis Arduino  ATmega328p. Perangkat ini mampu secara otomatis mengatur AC sesuai dengan pembacaan suhu dan kelembaban udara ruangan dengan menggunakan sebuah alat sensor DHT11, yang dimana dengan itu perangkat ini mampu mendeteksi kondisi lingkungan di dalam ruangan secara real-time dan mengatur pengoperasian AC secara otomatis agar suhu dan kelembaban tetap berada dalam rentang yang diinginkan. Perangkat ini juga menyediakan sebuah monitor LCD yang memungkinkan pengguna untuk melihat informasi suhu dan kelembaban ruangan secara langsung. Monitor LCD ini menggunakan protokol I2C untuk berkomunikasi dengan Arduino.


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
### ii. Hardware design and implementation details
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

Komponen yang dibutuhkan:

Arduino Uno - 1 buah
Breadboard - 2 buah
Resistor - 3 buah
LCD - 1 buah
LED - 2 buah
IC 7404 - 1 buah
DHT11 - 1 buah
Kabel jumper
DC Motor - 1 buah

Rangkaian fisik yang kami gunakan ini secara garis besar menggunakan breadboard dan kabel jumper untuk menyambungkan para komponen serta arduino uno sebagai otaknya. DC Motor pada rangkaian kami bekerja sebagai pengganti dari peran AC sebagai pengatur suhu ruangan. Perangkat ini secara otomatis membaca suhu dan kelembaban udara ruangan dengan menggunakan sensor DHT11 yang kemudian data akan diproses oleh arduino untuk mengatur suhu dari AC yang kita inginkan. Selain itu, suhu yang dibaca oleh sensor DHT11 dikirim ke arduino yang berbeda yang menyediakan sebuah monitor LCD yang terhubung dengan arduino agar user dapat melihat keterangan suhu ruangan dengan mengimplementasikan protokol I2C. Terdapat juga sebuah button controller yang dihubungkan dengan IC 7404 yang dengan arduino yang dapat digunakan untuk mengatur suhu AC secara manual dengan menggunakan sebuah konsep interrupt. Selain terhubung dengan arduino, IC 7404 juga terhubung dengan 2 LED.


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
### iii. Software implementation details
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

Sejak awal perancangan ide, rangkaian ini memiliki beberapa fitur diantaranya seperti penggunaan interrupt dengan menggunakan sebuah button, sensor DHT 11 untuk pengaturan suhu dan kelembaban udara ruangan, serta penggunaan sebuah protokol komunikasi I2C untuk menyambungkan ke sebuah monitor LCD yang akan menunjukkan keterangan suhu ruangan. 
Alur dari program yang dirancang akan berdasarkan mengikuti flowchart yang tertera pada makalah.


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
### iv. Test results and performance evaluation
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

Kami membuat rangkaian proteus dan fisik lalu melakukan percobaan pada suhu ruangan pada tempat kami berada, tujuannya untuk mensimulasikan keadaan pada ruangan yang ber-AC. Sedikit perlu ada perubahan pada kode program yang kita buat untuk menyesuaikan pada arduino. Penyesuaian tersebut adalah penentuan pin yang digunakan pada sensor DHT11 dan LCD, serta penyesuaian rpm DC Motor pada setiap tingkatan suhu pada ruangan. Jika suhu terbaca dibawah 18°C maka rpm dari DC Motor dikonfigurasikan paling kecil, jika suhu dibawah  25°C maka konfigurasi berubah menjadi medium pada rpm DC Motor, selanjutnya jika suhu lebih besar dari 25°C maka  rpm pada DC Motor akan dikonfigurasi pada tingkatan high. Button dihubungkan dengan IC 7404 lalu disambungkan dengan kedua dua LED yang berwarna merah dan hijau yang berfungsi sebagai penanda keadaan perangkat bekerja dalam warna hijau atau mati dalam warna merah.

Ketika kami menyalakan perangkat kami, button control dapat berfungsi dengan baik yang ditandai dengan menyalanya led hijau yang menandakan bahwa perangkat kami dalam kondisi berfungsi. LCD bekerja dengan baik pada awal perangkat dinyalakan, akan tetapi tampilan suhu ruangan tidak muncul pada LCD. DC Motor pada perangkat kami belum bekerja dengan baik.

Pada rangkaian proteus kami, semua fungsi yang kami buat berjalan dengan baik sesuai dengan fungsi yang kami buat. Button control bekerja dengan baik sesuai dengan fungsinya sebagai pengontrol perangkat. Sensor dapat menangkap data suhu ruangan dan  LCD dapat bekerja dengan baik dalam menampilkan data suhu ruangan. DC Motor bekerja dengan baik sesuai dengan skema penyesuaian rpm dengan tingkatan suhu pada ruangan.

Pada perangkat yang kami buat, kami menyadari kesalahan pada LCD mungkin disebabkan oleh LCD yang sudah tidak berfungsi dengan benar dan juga kode program yang belum optimal dan benar pada penyesuaian perangkat fisik kami. DC Motor yang tidak berjalan sesuai dengan fungsi juga menjadi hambatan untuk kami dalam membuat perangkat kami bisa disebabkan karena kami belum menyesuaikan nya dengan baik pada rangkaian fisik kami, mungkin kami perlu menambahkan beberapa komponen seperti driver shield untuk mengatur kerja dari DC Motor. 

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
### v. Conclusion and future work
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

Dalam proyek kami, kami bertujuan untuk mensimulasikan lingkungan ruangan ber-AC menggunakan setup fisik dan simulasi Proteus, yang melibatkan sensor DHT11, tampilan LCD, motor DC, dan tombol kontrol yang dihubungkan dengan Arduino. Simulasi Proteus kami berjalan dengan sukses, dengan semua komponen berfungsi seperti yang diharapkan: tombol kontrol secara efektif menghidupkan/mematikan perangkat, sensor DHT11 membaca suhu ruangan dengan akurat, LCD menampilkan suhu, dan motor DC menyesuaikan RPM sesuai dengan ambang suhu yang kami tetapkan.

Namun, dalam setup fisik, kami menghadapi beberapa masalah. Tombol kontrol dan LED bekerja dengan baik, menunjukkan status operasional perangkat dengan LED hijau dan status mati dengan LED merah. LCD diinisialisasi dengan benar tetapi gagal menampilkan pembacaan suhu ruangan. Selain itu, motor DC tidak beroperasi seperti yang diharapkan. Ketidaksesuaian ini menunjukkan adanya masalah potensial pada LCD fisik atau optimasi kode untuk perangkat keras. Kinerja motor mungkin dapat ditingkatkan dengan penambahan driver shield untuk mengatur RPM-nya berdasarkan pembacaan suhu.

Untuk proyek-proyek selanjutnya kami ingin meningkatkan fungsionalitas rangkaian asli kami, dimulai dari memverifikasi kabel dan koneksi LCD untuk memastikan komunikasi yang benar dengan Arduino, menguji LCD terlebih dahulu dengan kode sederhana untuk memeriksa fungsinya, dan melakukan pengujian menyeluruh pada setiap komponen secara individu untuk memastikan mereka bekerja dengan benar sebelum diintegrasikan ke dalam sistem lengkap agar menghasilkan produk yang lebih baik dari yang kami rancang sekarang
