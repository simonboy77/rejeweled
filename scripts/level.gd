class_name Level extends Object

var dim:Vector2
var blocks:PackedByteArray = []

var highScore = 0
var attempts = 0
var starRating = 0
var starOneScoreThreshold = 0
var starTwoScoreThreshold = 0
var starThreeScoreThreshold = 0

func _init(columns:int, rows:int, blockList:PackedByteArray):
	dim.x = columns
	dim.y = rows
	blocks = blockList
