all: game
	./game

game: game.o
	ld -o game game.o -L~/Documents/libraries/raylib/src -lraylib -lm -lpthread -lGL -ldl -lX11 -lc

game.o: game.asm
	fasm game.asm
