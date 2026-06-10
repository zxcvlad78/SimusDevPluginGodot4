class_name SimusNetHashedValues
extends RefCounted

@export var _data: Dictionary[Variant, int] = {}
@export var _data_id: Dictionary[int, Variant] = {}

func put_string(string: String) -> SimusNetHashedValues:
	var hash: int = SimusNetHash.hash64_salted(string)
	put_value(string, hash)
	return self

func put_value(value: Variant, hash_id: int) -> SimusNetHashedValues:
	if _data_id.has(hash_id):
		printerr("SimusNetHashedValues: collision detected! %s, %s" % [value, hash_id])
	_data[value] = hash_id
	_data_id[hash_id] = value
	return self

func get_hash_id_for(value: Variant, default: int = -1) -> int:
	return _data.get(value, default)

func get_value_from_hash_id(hash_id: int, default: Variant = null) -> Variant:
	return _data_id.get(hash_id, default)

func clear() -> SimusNetHashedValues:
	_data.clear()
	_data_id.clear()
	return self
