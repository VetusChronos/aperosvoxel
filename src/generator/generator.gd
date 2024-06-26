extends VoxelGeneratorScript
class_name Generator

const Structure = preload("./structure.gd")
const TreeGenerator = preload("./tree_generator.gd")
const HeightmapCurve = preload("./heightmap_curve.tres")
const MainMenu = preload("res://src/main_menu.gd")

var block_types = {
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
}

const _CHANNEL = VoxelBuffer.CHANNEL_TYPE

const _moore_dirs = [
	Vector3(-1, 0, -1),
	Vector3(0, 0, -1),
	Vector3(1, 0, -1),
	Vector3(-1, 0, 0),
	Vector3(1, 0, 0),
	Vector3(-1, 0, 1),
	Vector3(0, 0, 1),
	Vector3(1, 0, 1)
]

var _tree_structures := []

var _heightmap_min_y := int(HeightmapCurve.min_value)
var _heightmap_max_y := int(HeightmapCurve.max_value)
var _heightmap_range := 0
var _trees_min_y := 0
var _trees_max_y := 0

# Biomes
const BIOME_PLAINS = 0
const BIOME_FOREST = 1
const BIOME_MOUNTAINS = 2
const BIOME_DESERT = 3
const BIOME_RIVER = 4


func _init():
	var tree_generator = TreeGenerator.new()
	tree_generator.log_type = block_types.LOG
	tree_generator.leaves_type = block_types.LEAVES
	for i in 16:
		var s = tree_generator.generate()
		_tree_structures.append(s)

	var tallest_tree_height = 0
	for structure in _tree_structures:
		var h = int(structure.voxels.get_size().y)
		if tallest_tree_height < h:
			tallest_tree_height = h
	_trees_min_y = _heightmap_min_y
	_trees_max_y = _heightmap_max_y + tallest_tree_height

	HeightmapCurve.bake()


func _get_used_channels_mask() -> int:
	return 1 << _CHANNEL


func _generate_block(buffer: VoxelBuffer, origin_in_voxels: Vector3i, lod: int):
	var block_size := int(buffer.get_size().x)
	var oy := origin_in_voxels.y
	var chunk_pos := Vector3(
		origin_in_voxels.x >> 4,
		origin_in_voxels.y >> 4,
		origin_in_voxels.z >> 4)

	_heightmap_range = _heightmap_max_y - _heightmap_min_y

	if origin_in_voxels.y > _heightmap_max_y:
		buffer.fill(block_types.AIR, _CHANNEL)
	elif origin_in_voxels.y + block_size < _heightmap_min_y:
		buffer.fill(block_types.DIRT, _CHANNEL)
	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = _get_chunk_seed_2d(chunk_pos)

		var gx : int
		var gz := origin_in_voxels.z

		for z in block_size:
			gx = origin_in_voxels.x

			for x in block_size:
				var height := _get_height_at(gx, gz)
				var biome := _get_biome_at(gx, gz)
				var relative_height := height - oy

				if biome == BIOME_DESERT:
					if relative_height > block_size:
						buffer.fill_area(block_types.STONE, Vector3(x, 0, z), Vector3(x + 1, block_size, z + 1), _CHANNEL)
					elif relative_height > 0:
						buffer.fill_area(block_types.SAND, Vector3(x, 0, z), Vector3(x + 1, relative_height, z + 1), _CHANNEL)
						if relative_height < block_size and rng.randf() < 0.2:
							var foliage = block_types.DEAD_SHRUB
							if rng.randf() < 0.1:
								foliage = block_types.DEAD_SHRUB
							buffer.set_voxel(foliage, x, relative_height, z, _CHANNEL)
				elif biome == BIOME_RIVER:
					if height < 0 and oy < 0:
						var start_relative_height := 0
						if relative_height > 0:
							start_relative_height = relative_height
						buffer.fill_area(block_types.WATER_FULL,
							Vector3(x, start_relative_height, z),
							Vector3(x + 1, block_size, z + 1), _CHANNEL)
						if oy + block_size == 0:
							buffer.set_voxel(block_types.WATER_TOP, x, block_size - 1, z, _CHANNEL)
				else:
					if relative_height > block_size:
						buffer.fill_area(block_types.STONE, Vector3(x, 0, z), Vector3(x + 1, block_size, z + 1), _CHANNEL)
					elif relative_height > 0:
						buffer.fill_area(block_types.DIRT, Vector3(x, 0, z), Vector3(x + 1, relative_height, z + 1), _CHANNEL)
						if height >= 0:
							buffer.set_voxel(block_types.GRASS, x, relative_height - 1, z, _CHANNEL)
							if relative_height < block_size and rng.randf() < 0.2:
								var foliage = block_types.TALL_GRASS
								if rng.randf() < 0.1:
									foliage = block_types.DEAD_SHRUB
								buffer.set_voxel(foliage, x, relative_height, z, _CHANNEL)
					
					# Water
					if height < 0 and oy < 0:
						var start_relative_height := 0
						if relative_height > 0:
							start_relative_height = relative_height
						buffer.fill_area(block_types.WATER_FULL,
							Vector3(x, start_relative_height, z),
							Vector3(x + 1, block_size, z + 1), _CHANNEL)
						if oy + block_size == 0:
							# Surface block
							buffer.set_voxel(block_types.WATER_TOP, x, block_size - 1, z, _CHANNEL)

				gx += 1
			gz += 1

	if origin_in_voxels.y <= _trees_max_y and origin_in_voxels.y + block_size >= _trees_min_y:
		var voxel_tool := buffer.get_voxel_tool()
		var structure_instances := []

		_get_tree_instances_in_chunk(chunk_pos, origin_in_voxels, block_size, structure_instances)

		var block_aabb := AABB(Vector3(), buffer.get_size() + Vector3i(1, 1, 1))

		for dir in _moore_dirs:
			var ncpos : Vector3 = (chunk_pos + dir).round()
			_get_tree_instances_in_chunk(ncpos, origin_in_voxels, block_size, structure_instances)

		for structure_instance in structure_instances:
			var pos : Vector3 = structure_instance[0]
			var structure : Structure = structure_instance[1]
			var lower_corner_pos := pos - structure.offset
			var aabb := AABB(lower_corner_pos, structure.voxels.get_size() + Vector3i(1, 1, 1))

			if aabb.intersects(block_aabb):
				voxel_tool.paste_masked(lower_corner_pos, structure.voxels, 1 << VoxelBuffer.CHANNEL_TYPE, VoxelBuffer.CHANNEL_TYPE, block_types.AIR)

	buffer.compress_uniform_channels()


func _get_tree_instances_in_chunk(cpos: Vector3, offset: Vector3, chunk_size: int, tree_instances: Array):
	var rng := RandomNumberGenerator.new()
	rng.seed = _get_chunk_seed_2d(cpos)

	var biomes_blacklist : Array = [
		BIOME_MOUNTAINS, 
		BIOME_DESERT, 
		BIOME_PLAINS, 
		BIOME_RIVER
	]

	for i in 4:
		var pos := Vector3(rng.randi() % chunk_size, 0, rng.randi() % chunk_size)
		pos += cpos * chunk_size
		pos.y = _get_height_at(pos.x, pos.z)

		if pos.y > 0 and _get_biome_at(pos.x, pos.z) not in biomes_blacklist:
			pos -= offset
			var si := rng.randi() % len(_tree_structures)
			var structure : Structure = _tree_structures[si]
			tree_instances.append([pos.round(), structure])


static func _get_chunk_seed_2d(cpos: Vector3) -> int:
	return int(cpos.x) ^ (31 * int(cpos.z))


func _get_height_at(x: int, z: int) -> int:
	var t = 0.5 + 0.5 * Globals._terrain_noise.get_noise_2d(x, z)
	var height := int(HeightmapCurve.sample_baked(t))
	var biome_factor := _get_biome_factor(x, z)
	height += int(35 * biome_factor)
	return height


func _get_biome_at(x: int, z: int) -> int:
	var noise_value = Globals._biome_noise.get_noise_2d(x, z)
	if noise_value < -0.2:
		return BIOME_PLAINS
	elif noise_value < 0.2:
		return BIOME_FOREST
	elif noise_value < 0.8:
		return BIOME_DESERT
	elif noise_value < 0.2:
		return BIOME_RIVER
	else:
		return BIOME_PLAINS


func _get_biome_factor(x: int, z: int) -> float:
	var noise_value = Globals._biome_noise.get_noise_2d(x, z)
	if noise_value >= 0.2:
		return (noise_value - 0.2) / 0.8
	return 0.0


func _get_temperature_at(x: int, z: int) -> float:
	return Globals._temperature_noise.get_noise_2d(x, z)
