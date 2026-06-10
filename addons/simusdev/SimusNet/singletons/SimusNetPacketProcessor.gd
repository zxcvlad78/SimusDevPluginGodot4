class_name SimusNetPacketProcessor
extends SimusNetSingletonChild

static var _instance: SimusNetPacketProcessor

var _buffer: StreamPeerBuffer = StreamPeerBuffer.new()

static func get_instance() -> SimusNetPacketProcessor:
	return _instance

signal packet_received(peer_id: int, packet: PackedByteArray)

func _ready():
	_instance = self
	
	multiplayer.peer_packet.connect(_on_raw_packet)

func _on_raw_packet(peer_id: int, raw: PackedByteArray) -> void:
	_buffer.data_array = raw
	
	var header: SimusNetTransport.PACKET_HEADER = _buffer.get_u8()
	var compression_type: SimusNetTransport.PACKET_COMPRESSION = _buffer.get_u8()
	
	var compression_buffer_size: int = 0
	
	if compression_type > 0:
		compression_buffer_size = _buffer.get_u32()
	
	if header == SimusNetTransport.PACKET_HEADER.DEFAULT:
		var packet: PackedByteArray = _buffer.get_data(_buffer.get_available_bytes())[1]
		packet = _decompress(packet, compression_buffer_size, compression_type)
		packet_received.emit(peer_id, packet)
	
	if header == SimusNetTransport.PACKET_HEADER.BATCH:
		var packets: PackedByteArray = _buffer.get_data(_buffer.get_available_bytes())[1]
		packets = _decompress(packets, compression_buffer_size, compression_type)
		for packet in SimusNetArguments.deserialize(packets):
			packet_received.emit(peer_id, packet)
	
	SimusNetProfiler._put_down_packet()
	SimusNetProfiler._instance._put_down_traffic(raw.size() + 3)

func _decompress(bytes: PackedByteArray, og_size: int, packet_compression: SimusNetTransport.PACKET_COMPRESSION) -> PackedByteArray:
	if packet_compression == SimusNetTransport.PACKET_COMPRESSION.COMPRESSED_DEFLATE:
		return bytes.decompress(og_size, FileAccess.COMPRESSION_DEFLATE)
	if packet_compression == SimusNetTransport.PACKET_COMPRESSION.COMPRESSED_ZSTD:
		return bytes.decompress(og_size, FileAccess.COMPRESSION_ZSTD)
	
	return bytes
