all: game
	rm ./game.o
	./game

game: game.o
	ld -o game game.o -L./raylib/src -lraylib -lm -lpthread -lGL -ldl -lX11 -lc

game.o: game.asm
	fasm game.asm
