extends Node
class_name Biome

const HeightmapCurve = preload("./heightmap_curve.tres")

const _CHANNEL = VoxelBuffer.CHANNEL_TYPE

# TODO: Read from a JSON
var block_types : Dictionary = {
	"AIR": 0,
	"DIRT": 1,
	"GRASS": 2,
	"LOG": 4,
	"WATER_FULL": 14,
	"WATER_TOP": 13,
	"LEAVES": 25,
	"TALL_GRASS": 8,
	"DEAD_SHRUB": 26,
	"STONE": 27,
	"SAND": 28,
	"SNOW": 29
}

# TODO: Read from a JSON
# TODO: Set the biome information by a JSON file
var biomes : Dictionary = {
	"BIOME_PLAINS": 0,
	"BIOME_FOREST": 1,
	"BIOME_DESERT": 2,
	"BIOME_SAVANNA": 3,
	"BIOME_TAIGA": 4,
	"BIOME_SWAMP": 5,
	"BIOME_TUNDRA": 6,
	"BIOME_SNOWY_FOREST": 7
}


# Set terrain height based on curve
func _get_height_at(x: int, z: int) -> int:
	var t = 0.5 + 0.5 * Globals._terrain_noise.get_noise_2d(x, z)
	var height = int(HeightmapCurve.sample_baked(t))
	return height


# TODO: Determine biome based on humidity too
func _get_biome_at(x: int, z: int) -> int:
	var temperature = (Globals._temperature_noise.get_noise_2d(x, z) + 1) / 2 # Normalizing to [0, 1]
	var humidity = (Globals._humidity_noise.get_noise_2d(x, z) + 1) / 2 # Normalizing to [0, 1]

	temperature = temperature * 1.2 - 0.1 # Expanding to [-0.1, 1.1]
	humidity = humidity * 1.2 - 0.1 # Expanding to [-0.1, 1.1]

	#print("Temperature: ", temperature, ", Humidity: ", humidity)
	
	var biomes_limits = [
		[0.65, biomes.BIOME_DESERT],
		[0.45, biomes.BIOME_SAVANNA],
		[0.35, biomes.BIOME_FOREST],
		[0.4, biomes.BIOME_PLAINS],
		[0.35, biomes.BIOME_SNOWY_FOREST]
	]
	
	for limit in biomes_limits:
		if temperature > limit[0]:
			return limit[1]

	return biomes.BIOME_PLAINS


##### BIOMES #####
# TODO: Simplify this to use information 
# from a JSON file containing the characteristics of each biome


func _generate_desert(buffer: VoxelBuffer, x: int, z: int, rel_height: int, block_size: int, rng: RandomNumberGenerator):
	if rel_height > block_size:
		buffer.fill_area(block_types.SAND, Vector3(x, 0, z), Vector3(x + 1, block_size, z + 1), _CHANNEL)
		buffer.fill_area(block_types.STONE, Vector3(x, 0, z), Vector3(x + 1, rel_height - 4, z + 1), _CHANNEL)
	elif rel_height > 0:
		buffer.fill_area(block_types.SAND, Vector3(x, 0, z), Vector3(x + 1, rel_height, z + 1), _CHANNEL)
		if rel_height < block_size and rng.randf() < 0.2:
			buffer.set_voxel(block_types.DEAD_SHRUB, x, rel_height, z, _CHANNEL)


func _generate_plains(buffer: VoxelBuffer, x: int, z: int, rel_height: int, block_size: int, height: int, rng: RandomNumberGenerator):
	if rel_height > block_size:
		buffer.fill_area(block_types.STONE, Vector3(x, 0, z), Vector3(x + 1, block_size, z + 1), _CHANNEL)
	elif rel_height > 0:
		buffer.fill_area(block_types.DIRT, Vector3(x, 0, z), Vector3(x + 1, rel_height - 1, z + 1), _CHANNEL)
		buffer.set_voxel(block_types.GRASS, x, rel_height - 1, z, _CHANNEL)
		if rel_height < block_size and rng.randf() < 0.2:
			buffer.set_voxel(block_types.TALL_GRASS, x, rel_height, z, _CHANNEL)


func _generate_savanna(buffer: VoxelBuffer, x: int, z: int, rel_height: int, block_size: int, rng: RandomNumberGenerator):
	if rel_height > block_size:
		buffer.fill_area(block_types.DIRT, Vector3(x, 0, z), Vector3(x + 1, block_size, z + 1), _CHANNEL)
	elif rel_height > 0:
		buffer.fill_area(block_types.DIRT, Vector3(x, 0, z), Vector3(x + 1, rel_height - 1, z + 1), _CHANNEL)
		buffer.set_voxel(block_types.GRASS, x, rel_height - 1, z, _CHANNEL)
		if rel_height < block_size and rng.randf() < 0.2:
			var foliage = block_types.DEAD_SHRUB
			if rng.randf() < 0.1:
				foliage = block_types.DEAD_SHRUB
			buffer.set_voxel(foliage, x, rel_height, z, _CHANNEL)


func _generate_snowy_forest(buffer: VoxelBuffer, x: int, z: int, rel_height: int, block_size: int, height: int, rng: RandomNumberGenerator):
	if rel_height > block_size:
		buffer.fill_area(block_types.DIRT, Vector3(x, 0, z), Vector3(x + 1, block_size, z + 1), _CHANNEL)
	elif rel_height > 0:
		buffer.fill_area(block_types.DIRT, Vector3(x, 0, z), Vector3(x + 1, rel_height, z + 1), _CHANNEL)
		if height >= 0:
			buffer.set_voxel(block_types.SNOW, x, rel_height - 1, z, _CHANNEL)


func _generate_default(buffer: VoxelBuffer, x: int, z: int, rel_height: int, block_size: int, height: int, rng: RandomNumberGenerator):
	if rel_height > block_size:
		buffer.fill_area(block_types.DIRT, Vector3(x, 0, z), Vector3(x + 1, block_size, z + 1), _CHANNEL)
	elif rel_height > 0:
		buffer.fill_area(block_types.DIRT, Vector3(x, 0, z), Vector3(x + 1, rel_height, z + 1), _CHANNEL)
		if height >= 0:
			buffer.set_voxel(block_types.GRASS, x, rel_height - 1, z, _CHANNEL)
			if rel_height < block_size and rng.randf() < 0.2:
				var foliage = block_types.TALL_GRASS
				if rng.randf() < 0.1:
					block_types.TALL_GRASS
				buffer.set_voxel(foliage, x, rel_height, z, _CHANNEL)
