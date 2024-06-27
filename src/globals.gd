extends Node

@export var _biome_noise : FastNoiseLite = FastNoiseLite.new()
@export var _terrain_noise : FastNoiseLite = FastNoiseLite.new()
@export var _temperature_noise : FastNoiseLite = FastNoiseLite.new()
@export var _humidity_noise : FastNoiseLite = FastNoiseLite.new()
@export var _erosion_noise : FastNoiseLite = FastNoiseLite.new()
@export var _cave_noise : FastNoiseLite = FastNoiseLite.new()

var random_seed : String


func set_noise_seed(seed: int) -> void:
	_biome_noise.seed = int(random_seed)
	_terrain_noise.seed = seed
	_temperature_noise.seed = int(random_seed)
	_humidity_noise.seed = int(random_seed)
	_erosion_noise.seed = int(random_seed)
	_cave_noise.seed = int(random_seed)
