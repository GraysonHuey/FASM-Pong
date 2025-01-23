# FASM Pong
FASM Pong is a very simple implementation of the classic game "Pong" but in x86_64 Assembly.</br>
This project is not complete yet, so stay tuned for future updates!
</br>
</br>
## How to install
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
git clone https://github.com/raysan5/raylib --depth 1
```
Finally, compile and run the game! Using the command below will use the Makefile to compile the assembly file. You can also run './game' after you have compiled if you do not wish to recompile.
```shell
make
```
