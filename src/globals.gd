extends Node

@export var _biome_noise : FastNoiseLite = FastNoiseLite.new()
@export var _terrain_noise : FastNoiseLite = FastNoiseLite.new()
@export var _temperature_noise : FastNoiseLite = FastNoiseLite.new()
@export var _erosion_noise : FastNoiseLite = FastNoiseLite.new()

var random_seed : String
var _seed : int


func set_noise_seed(seed: int) -> void:
	_biome_noise.seed = seed
	_terrain_noise.seed = seed
	_temperature_noise.seed = seed
	_erosion_noise.seed = seed
