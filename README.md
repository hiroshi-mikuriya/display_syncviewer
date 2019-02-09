Display SyncViewer
=============

# About

SyncViewerに定期的にアクセスして情報を得てLEDを発光させます。

# Setup

Instatll bcm2835 to write FPGA register.

```
$ sudo wget http://www.airspayce.com/mikem/bcm2835/bcm2835-1.44.tar.gz
$ tar zxvf bcm2835-1.44.tar.gz
$ cd bcm2835-1.44/
$ sudo ./configure
$ sudo make
$ cd src
$ cc -shared bcm2835.o -o libbcm2835.so
$ sudo install libbcm2835.so /usr/local/lib
$ cd ../
$ sudo make install
$ sudo ldconfig
```

# Link


