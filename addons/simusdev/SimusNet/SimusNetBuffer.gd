extends RefCounted
class_name SimusNetBuffer

var bytes: PackedByteArray = PackedByteArray()

var __position: int = 0

var _buffer: PackedByteArray = PackedByteArray()
var _buffer_write_type: PackedByteArray = PackedByteArray()

enum DataType {
	BOOL_TRUE,
	BOOL_FALSE,
	INT_8,
	INT_16,
	INT_32,
	INT_64,
	INT_U8,
	INT_U16,
	INT_U32,
	INT_U64,
	FLOAT,
	DOUBLE,
}

func seek(position: int) -> SimusNetBuffer:
	__position = position
	return self

func clear() -> SimusNetBuffer:
	bytes.clear()
	_buffer.clear()
	_buffer_write_type.clear()
	__position = 0
	return self

func _write_type(type: DataType, data: PackedByteArray = PackedByteArray()) -> void:
	_buffer_write_type.clear()
	_buffer_write_type.resize(1)
	_buffer_write_type.encode_u8(0, type)
	bytes.append_array(_buffer_write_type)
	if data.size() > 0:
		bytes.append_array(data)

func _read_type() -> DataType:
	var result: DataType = bytes.decode_u8(__position)
	__position += 1
	return result

func write_int(value: int) -> SimusNetBuffer:
	return self

func write_bool(value: bool) -> SimusNetBuffer:
	if value == true:
		_write_type(DataType.BOOL_TRUE)
	else:
		_write_type(DataType.BOOL_FALSE)
	return self

func read_bool() -> Variant:
	var type: DataType = _read_type()
	if type == DataType.BOOL_TRUE:
		return true
	return false

func write_int_u8(value: int) -> SimusNetBuffer:
	_buffer.clear()
	_buffer.resize(1)
	_buffer.encode_u8(0, value)
	_write_type(DataType.INT_U8, _buffer)
	return self

func read_int_u8() -> int:
	var type: DataType = _read_type()
	if type == DataType.INT_U8:
		var result: int = bytes.decode_u8(__position)
		__position += 1
		return result
	__position += 1
	return 0

func write_int_u16(value: int) -> SimusNetBuffer:
	_buffer.clear()
	_buffer.resize(2)
	_buffer.encode_u16(0, value)
	_write_type(DataType.INT_U16, _buffer)
	return self

func read_int_u16() -> int:
	var type: DataType = _read_type()
	if type == DataType.INT_U16:
		var result: int = bytes.decode_u16(__position)
		__position += 2
		return result
	__position += 2
	return 0

func write_int_u32(value: int) -> SimusNetBuffer:
	_buffer.clear()
	_buffer.resize(4)
	_buffer.encode_u32(0, value)
	_write_type(DataType.INT_U32, _buffer)
	return self

func read_int_u32() -> int:
	var type: DataType = _read_type()
	if type == DataType.INT_U32:
		var result: int = bytes.decode_u32(__position)
		__position += 4
		return result
	__position += 4
	return 0

func write_int_u64(value: int) -> SimusNetBuffer:
	_buffer.clear()
	_buffer.resize(8)
	_buffer.encode_u64(0, value)
	_write_type(DataType.INT_U64, _buffer)
	return self

func read_int_u64() -> int:
	var type: DataType = _read_type()
	if type == DataType.INT_U64:
		var result: int = bytes.decode_u64(__position)
		__position += 8
		return result
	__position += 8
	return 0

func write_int_8(value: int) -> SimusNetBuffer:
	_buffer.clear()
	_buffer.resize(1)
	_buffer.encode_s8(0, value)
	_write_type(DataType.INT_8, _buffer)
	return self

func read_int_8() -> int:
	var type: DataType = _read_type()
	if type == DataType.INT_8:
		var result: int = bytes.decode_s8(__position)
		__position += 1
		return result
	__position += 1
	return 0

func write_int_16(value: int) -> SimusNetBuffer:
	_buffer.clear()
	_buffer.resize(2)
	_buffer.encode_s16(0, value)
	_write_type(DataType.INT_16, _buffer)
	return self

func read_int_16() -> int:
	var type: DataType = _read_type()
	if type == DataType.INT_16:
		var result: int = bytes.decode_s16(__position)
		__position += 2
		return result
	__position += 2
	return 0

func write_int_32(value: int) -> SimusNetBuffer:
	_buffer.clear()
	_buffer.resize(4)
	_buffer.encode_s32(0, value)
	_write_type(DataType.INT_32, _buffer)
	return self

func read_int_32() -> int:
	var type: DataType = _read_type()
	if type == DataType.INT_32:
		var result: int = bytes.decode_s32(__position)
		__position += 4
		return result
	__position += 4
	return 0

func write_int_64(value: int) -> SimusNetBuffer:
	_buffer.clear()
	_buffer.resize(8)
	_buffer.encode_s64(0, value)
	_write_type(DataType.INT_64, _buffer)
	return self

func read_int_64() -> int:
	var type: DataType = _read_type()
	if type == DataType.INT_64:
		var result: int = bytes.decode_s64(__position)
		__position += 8
		return result
	__position += 8
	return 0

func get_position() -> int:
	return __position
