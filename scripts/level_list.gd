extends Node2D

const random = Globals.BLOCK_RANDOM
const empty = Globals.BLOCK_EMPTY
const rainb = Globals.BLOCK_RAINBOW
const gap = Globals.BLOCK_GAP
const saw = Globals.BLOCK_SAW
const bomb = Globals.BLOCK_BOMB
const star = Globals.BLOCK_STAR

var level_1 = Level.new(4, 4, PackedByteArray([
	random, random, random, random,
	random, random, random, random,
	random, random, random, random,
	random, random, random, random,
]))

var level_2 = Level.new(4, 5, PackedByteArray([
	random, random, random, random,
	random, gap,    gap,    random,
	random, gap,    gap,    random,
	random, random, random, random,
	random, random, random, random
]))

var level_3 = Level.new(5, 7, PackedByteArray([
	empty, empty, empty, empty, gap,
	empty, gap,   gap,   gap,   empty,
	empty, empty, empty, empty, empty,
	empty, gap,   gap,   gap,   empty,
	empty, gap,   empty, gap,   empty,
	empty, gap,   empty, empty, empty,
	empty, gap,   gap,   gap,   empty,
]))

var level_4 = Level.new(4, 4, PackedByteArray([
	empty, empty, empty, empty,
	empty, empty, empty, empty,
	empty, empty, empty, empty,
	empty, empty, empty, empty,
]))

var level_5 = Level.new(8, 8, PackedByteArray([
	gap,   gap,   gap,   gap,   gap,   gap,   gap,   empty,
	empty, empty, empty, empty, empty, empty, gap,   empty,
	empty, gap,   gap,   gap,   gap,   empty, gap,   empty,
	empty, gap,   empty, empty, gap,   empty, gap,   empty,
	empty, gap,   empty, gap,   gap,   empty, gap,   empty,
	empty, gap,   empty, empty, empty, empty, gap,   empty,
	empty, gap,   gap,   gap,   gap,   gap,   gap,   empty,
	empty, empty, empty, empty, empty, empty, empty, empty
]))

var level_6 = Level.new(8, 8, PackedByteArray([
	empty, gap,   gap,   gap,   gap,   gap,   gap,   empty,
	empty, gap,   empty, empty, empty, empty, gap,   empty,
	empty, empty, empty, empty, empty, empty, empty, empty,
	empty, gap,   empty, empty, empty, empty, gap,   empty,
	empty, gap,   empty, empty, empty, empty, gap,   empty,
	empty, gap,   empty, gap,   gap,   empty, gap,   empty,
	empty, gap,   empty, gap,   gap,   empty, gap,   empty,
	empty, empty, empty, gap,   gap,   empty, empty, empty
]))

var level_7 = Level.new(8, 8, PackedByteArray([
	empty, empty, empty, empty, empty, empty, empty, empty,
	empty, empty, empty, empty, empty, empty, empty, empty,
	empty, empty, empty, empty, empty, empty, empty, empty,
	empty, empty, empty, empty, empty, empty, empty, empty,
	empty, empty, empty, empty, empty, empty, empty, empty,
	empty, empty, empty, empty, empty, empty, empty, empty,
	empty, empty, empty, empty, empty, empty, empty, empty,
	empty, empty, empty, empty, empty, empty, empty, empty,
]))

var level_8 = Level.new(8, 8, PackedByteArray([
	saw,    random, random, random, random, random, random, saw,
	saw,    saw,    random, random, random, random, saw,    random,
	random, random, saw,    random, random, saw,    random, random,
	random, random, random, saw,    saw,    random, random, random,
	random, random, random, random, random, random, random, random,
	random, random, random, saw   , random, saw,    random, random,
	random, random, saw,    random, random, random, saw,    random,
	saw,    random, random, random, random, random, random, saw,
]))

var level_9 = Level.new(8, 8, PackedByteArray([
	random, random, random, random, random, random, random, random,
	random, random, random, random, random, random, random, random,
	random, random, random, random, random, random, random, random,
	random, random, random, random, random, random, random, random,
	random, random, random, random, random, random, random, random,
	random, random, random, random, random, random, random, random,
	random, random, random, random, random, random, random, random,
	random, random, random, random, random, random, random, random,
]))

var level_10 = Level.new(8, 8, PackedByteArray([
	random, random, random, random, random, random, random, random,
	random, random, random, rainb,  random, random, random, random,
	random, random, bomb,   star,   saw,    random, random, random,
	random, random, random, random, random, random, random, random,
	random, random, random, random, random, random, random, random,
	random, random, random, random, random, random, random, random,
	random, random, random, random, random, saw,    bomb,   random,
	random, random, random, random, random, random, random, random,
]))

var level_11 = Level.new(2, 3, PackedByteArray([
	random, random,
	random, random,
	random, random,
]))

var level_12 = Level.new(7, 7, PackedByteArray([
	random, random, random, random, random, random, random,
	random, random, random, random, random, random, random,
	random, random, saw,    saw,    saw,    random, random,
	random, random, saw,    bomb,   saw,    random, random,
	random, random, saw,    saw,    saw,    random, random,
	random, random, random, random, random, random, random,
	random, random, random, random, random, random, random,
]))
