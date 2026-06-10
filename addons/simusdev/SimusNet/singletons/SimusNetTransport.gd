class_name SimusNetTransport
extends Node

@export var config: SimusNetTransportConfig

var _api: SceneMultiplayer

const MTU: int = 1400

enum PACKET_COMPRESSION {
	UNCOMPRESSED,
	COMPRESSED_DEFLATE,
	COMPRESSED_ZSTD,
}

enum PACKET_HEADER {
	DEFAULT,
	BATCH,
}

var _buffer: StreamPeerBuffer = StreamPeerBuffer.new()

# queue_id -> packets
var _queue: Dictionary[String, Array] = {}

var _timer: Timer

func _ready() -> void:
	if !config:
		config = SimusNetTransportConfig.new()
	
	_api = multiplayer as SceneMultiplayer
	
	_timer = Timer.new()
	_timer.autostart = true
	_timer.wait_time = 1.0 / config.tickrate
	_timer.timeout.connect(_on_tick)
	add_child(_timer)

func _on_tick() -> void:
	_timer.wait_time = 1.0 / config.tickrate
	flush()

func flush() -> void:
	if _queue.is_empty():
		return
	
	var queue: Dictionary[String, Array] = _queue.duplicate()
	
	for queue_id: String in queue:
		var id_split: PackedStringArray = queue_id.split(":")
		
		var peer: int = int(id_split[0])
		var mode: int = int(id_split[1])
		var channel: int = int(id_split[2])
		
		var packets: Array = queue[queue_id]
		
		if packets.size() == 1:
			var packet: Dictionary = packets[0]
			_send_raw(
				packet.bytes,
				peer,
				mode,
				channel,
				PACKET_HEADER.DEFAULT
			)
			
			continue
		
		
		var batch: int = 0
		
		var batches: Dictionary[int, Dictionary] = {}
		
		for packet: Dictionary in packets:
			if (packet.bytes.size() >= MTU * 0.85):
				_send_raw(
					packet.bytes,
					peer,
					mode,
					channel,
					PACKET_HEADER.DEFAULT
				)
				
				continue
			
			var data: Dictionary = batches.get_or_add(batch, {})
			var saved_bytes: int = data.get_or_add("saved_bytes", 0)
			if saved_bytes >= MTU * 0.85:
				batch += 1
			
			data = batches.get_or_add(batch, {})
			var buffer: Array = data.get_or_add("buffer", [])
			
			buffer.append(packet.bytes)
			
			saved_bytes = data.get_or_add("saved_bytes", 0)
			saved_bytes += packet.bytes.size()
			data.saved_bytes = saved_bytes
			
			
		
		for batch_id: int in batches:
			var buffer: Array = batches[batch_id].buffer
			var serialized_bytes: PackedByteArray = SimusNetArguments.serialize(buffer)
			_send_raw(serialized_bytes, peer, mode, channel, PACKET_HEADER.BATCH)
	
	_queue.clear()


func send_packet(packet: PackedByteArray, peer: int, 
	mode: MultiplayerPeer.TransferMode = MultiplayerPeer.TransferMode.TRANSFER_MODE_RELIABLE, 
	channel: int = 0, immediate: bool = false) -> void:
		if immediate or !config.enabled:
			_send_raw(packet, peer, mode, channel)
			return
		
		var queue_id: String = "%s:%s:%s" % [peer, mode, channel]
		var packets: Array = _queue.get_or_add(queue_id, [])
		packets.append(
			{
				"bytes": packet,
				"peer": peer,
				"mode": mode,
				"channel": channel,
			}
		)

func _send_raw(packet: PackedByteArray, peer: int, 
	mode: MultiplayerPeer.TransferMode = MultiplayerPeer.TransferMode.TRANSFER_MODE_RELIABLE, 
	channel: int = 0, header: PACKET_HEADER = PACKET_HEADER.DEFAULT) -> void:
		var compression_type: PACKET_COMPRESSION = PACKET_COMPRESSION.UNCOMPRESSED
		var original_size: int = packet.size()
		
		_buffer.clear()
		_buffer.put_u8(header)
		
		if config.compression_enabled:
			var has_compression: bool = false
			if packet.size() >= config.compression_threshold_deflate:
				compression_type = PACKET_COMPRESSION.COMPRESSED_DEFLATE
				
				if packet.size() >= config.compression_threshold_zstd:
					compression_type = PACKET_COMPRESSION.COMPRESSED_ZSTD
				
				has_compression = true
				
			
			
			_buffer.put_u8(compression_type)
			
			if has_compression:
				if compression_type == PACKET_COMPRESSION.COMPRESSED_DEFLATE:
					packet = packet.compress(FileAccess.CompressionMode.COMPRESSION_DEFLATE)
				if compression_type == PACKET_COMPRESSION.COMPRESSED_ZSTD:
					packet = packet.compress(FileAccess.CompressionMode.COMPRESSION_ZSTD)
				
				_buffer.put_u32(original_size)
			
		else:
			_buffer.put_u8(compression_type)
		
		_buffer.put_data(packet)
		
		_api.send_bytes(_buffer.data_array, peer, mode, channel)
		
		SimusNetProfiler._put_up_packet()
		SimusNetProfiler._instance._put_up_traffic(_buffer.data_array.size() + 3)
