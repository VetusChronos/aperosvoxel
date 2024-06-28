extends VoxelGeneratorScript
class_name Generator

const Structure = preload("./structure.gd")
const TreeGenerator = preload("./tree_generator.gd")
const HeightmapCurve = preload("./heightmap_curve.tres")

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

var _voxel_library = preload("res://src/blocks/voxel_library.tres")

var _biomes = Biome.new()
var tree_generator = TreeGenerator.new()

var _tree_structures : Array = []
var _heightmap_range : int = 0
var _heightmap_min_y : int = 0
var _heightmap_max_y : int = 128
var _trees_min_y : int = 0
var _trees_max_y : int = 0

var rng = RandomNumberGenerator.new()


func _init():
	_generate_tree_structures()
	_heightmap_range = _heightmap_max_y - _heightmap_min_y
	_biomes.HeightmapCurve.bake()


func _generate_tree_structures():
	tree_generator.log_type = _biomes.block_types.LOG
	tree_generator.leaves_type = _biomes.block_types.LEAVES
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


func _generate_block(buffer: VoxelBuffer, origin_in_voxels: Vector3i, lod: int):
	var block_size := int(buffer.get_size().x)
	var oy := origin_in_voxels.y
	var chunk_pos := Vector3(
		origin_in_voxels.x >> 4,
		origin_in_voxels.y >> 4,
		origin_in_voxels.z >> 4)

	if origin_in_voxels.y > _heightmap_max_y:
		buffer.fill(_biomes.block_types.AIR, _biomes._CHANNEL)
	elif origin_in_voxels.y + block_size < _heightmap_min_y:
		buffer.fill(_biomes.block_types.DIRT, _biomes._CHANNEL)
	else:
		_fill_chunk(buffer, origin_in_voxels, block_size, chunk_pos, oy)
		_generate_trees(buffer, origin_in_voxels, block_size, chunk_pos)

	buffer.compress_uniform_channels()


func _fill_chunk(buffer: VoxelBuffer, origin_in_voxels: Vector3i, block_size: int, chunk_pos: Vector3, oy: int):
	rng.seed = _get_chunk_seed_2d(chunk_pos)

	for z in range(block_size):
		for x in range(block_size):
			var gx = origin_in_voxels.x + x
			var gz = origin_in_voxels.z + z
			var height = _biomes._get_height_at(gx, gz)
			var biome = _biomes._get_biome_at(gx, gz)
			var relative_height = height - oy

			match biome:
				_biomes.biomes.BIOME_DESERT:
					_biomes._generate_desert(buffer, x, z, relative_height, block_size, rng)
				_biomes.biomes.BIOME_PLAINS:
					_biomes._generate_plains(buffer, x, z, relative_height, block_size, height, rng)
				_biomes.biomes.BIOME_SAVANNA:
					_biomes._generate_savanna(buffer, x, z, relative_height, block_size, rng)
				_biomes.biomes.BIOME_SNOWY_FOREST:
					_biomes._generate_snowy_forest(buffer, x, z, relative_height, block_size, height, rng)
				_:
					_biomes._generate_default(buffer, x, z, relative_height, block_size, height, rng)

			# Water generation
			if height < 0:
				var start_relative_height := 0
				if relative_height > 0:
					start_relative_height = relative_height
				if oy < 0:
					buffer.fill_area(_biomes.block_types.WATER_FULL,
						Vector3(x, start_relative_height, z),
						Vector3(x + 1, block_size, z + 1), _biomes._CHANNEL)
					if oy + block_size == 0:
						# Surface block
						buffer.set_voxel(_biomes.block_types.WATER_TOP, x, block_size - 1, z, _biomes._CHANNEL)


func _generate_trees(buffer: VoxelBuffer, origin_in_voxels: Vector3i, block_size: int, chunk_pos: Vector3):
	if origin_in_voxels.y <= _trees_max_y and origin_in_voxels.y + block_size >= _trees_min_y:
		var voxel_tool = buffer.get_voxel_tool()
		var structure_instances : Array = []
		_get_tree_instances_in_chunk(chunk_pos, origin_in_voxels, block_size, structure_instances)

		var block_aabb = AABB(Vector3(), buffer.get_size() + Vector3i(1, 1, 1))

		for structure_instance in structure_instances:
			var pos = structure_instance[0]
			var structure = structure_instance[1]
			var lower_corner_pos = pos - structure.offset
			var aabb = AABB(lower_corner_pos, structure.voxels.get_size() + Vector3i(1, 1, 1))

			if aabb.intersects(block_aabb):
				voxel_tool.paste_masked(lower_corner_pos, structure.voxels, 1 << VoxelBuffer.CHANNEL_TYPE, 
					VoxelBuffer.CHANNEL_TYPE, _biomes.block_types.AIR)


func _get_tree_instances_in_chunk(cpos: Vector3, offset: Vector3, chunk_size: int, tree_instances: Array):
	var rng = RandomNumberGenerator.new()
	rng.seed = _get_chunk_seed_2d(cpos)

	var biomes_blacklist = [
		_biomes.biomes.BIOME_DESERT,
		_biomes.biomes.BIOME_PLAINS
	]

	for i in 4:
		var pos = Vector3(rng.randi() % chunk_size, 0, rng.randi() % chunk_size)
		pos += cpos * chunk_size
		pos.y = _biomes._get_height_at(pos.x, pos.z)

		if pos.y > 0 and _biomes._get_biome_at(pos.x, pos.z) not in biomes_blacklist:
			pos -= offset
			var si = rng.randi() % len(_tree_structures)
			var structure = _tree_structures[si]
			tree_instances.append([pos.round(), structure])


static func _get_chunk_seed_2d(cpos: Vector3) -> int:
	return int(cpos.x) ^ (31 * int(cpos.z))
