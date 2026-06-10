class_name SimusNetTransportConfig
extends Resource

@export var enabled: bool = true
@export var compression_enabled: bool = true
@export var compression_threshold_deflate: int = 1024
@export var compression_threshold_zstd: int = 4096
@export var tickrate: float = 60.0
