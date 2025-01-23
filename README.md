# FASM Pong
FASM Pong is a very simple implementation of the classic game "Pong" but in x86_64 Assembly.</br>
This project is not complete yet, so stay tuned for future updates!
</br>
</br>
## ⚠️ WARNING ⚠️
This game was developed and tested on Ubuntu 22.04.1 (64-bit). Any 64-bit Debian-based systems will most likely work, but any attempts to run this game on any OS other than Ubuntu ***might not work***.</br>
Please only try to play this game on a Linux machine. I know that this WILL NOT work on Windows. Also, make sure you use a 64-bit OS. This will not work on 32-bit.
</br>
</br>
## How to play!
First, you need to install all of the required packages.
```shell
sudo apt-get install fasm make binutils
```
Next, clone this repository and open it
```shell
git clone https://github.com/GraysonHuey/FASM-Pong.git --depth 1 && cd FASM-Pong
```
Before you try to run the game, make sure you install raylib
```shell
git clone https://github.com/raysan5/raylib.git --depth 1
```
Finally, compile and run the game! Using the command below will use the Makefile to compile the assembly file. You can also run './game' after you have compiled if you do not wish to recompile.
```shell
make
```
