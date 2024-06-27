
const TYPE_BLOCK = 0
const TYPE_ITEM = 1

var type : int = TYPE_BLOCK
var id : int = 0
#var count : int = 0

# TODO: Can't type hint self
func duplicate():
	var d = get_script().new()
	d.type = type
	d.id = id
	return d
