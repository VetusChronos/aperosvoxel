const Structure = preload("./structure.gd")

var trunk_len_min := 4
var trunk_len_max := 8
var log_type := 1
var leaves_type := 2
var channel := VoxelBuffer.CHANNEL_TYPE


func generate() -> Structure:
	var voxels := {}
	# Trunk
	var trunk_len := int(randf_range(trunk_len_min, trunk_len_max))
	for y in range(trunk_len):
		voxels[Vector3(0, y, 0)] = log_type

	# Leaves
	var leaves_start := trunk_len - 3
	var leaves_end := trunk_len + 2
	for y in range(leaves_start, leaves_end):
		for x in range(-2, 3):
			for z in range(-2, 3):
				if abs(x) == 2 and abs(z) == 2 and (y == leaves_start or y == leaves_end):
					# Skip corners on the top and bottom layer
					continue
				if not (x == 0 and y == trunk_len and z == 0):  # Skip trunk position
					voxels[Vector3(x, y, z)] = leaves_type

	# Make structure
	var aabb := AABB()
	for pos in voxels:
		aabb = aabb.expand(pos)

	var structure := Structure.new()
	structure.offset = -aabb.position

	var buffer := structure.voxels
	buffer.create(int(aabb.size.x) + 1, int(aabb.size.y) + 1, int(aabb.size.z) + 1)

	for pos in voxels:
		var rpos = pos + structure.offset
		var v = voxels[pos]
		buffer.set_voxel(v, rpos.x, rpos.y, rpos.z, channel)

	return structure
