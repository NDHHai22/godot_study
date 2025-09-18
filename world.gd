extends Node2D

# Giới hạn map (có thể điều chỉnh theo ý muốn)
const MAP_LEFT_LIMIT = -100.0
const MAP_RIGHT_LIMIT = 2000.0
const MAP_TOP_LIMIT = -200.0
const MAP_BOTTOM_LIMIT = 800.0

@onready var player = $CharacterBody2D

func _ready() -> void:
	# Thiết lập giới hạn map
	pass

func _process(_delta: float) -> void:
	# Kiểm tra và giới hạn vị trí player
	if player:
		limit_player_position()

func limit_player_position():
	var player_pos = player.global_position
	var clamped_pos = player_pos

	# Giới hạn theo trục X (trái - phải)
	clamped_pos.x = clamp(player_pos.x, MAP_LEFT_LIMIT, MAP_RIGHT_LIMIT)

	# Giới hạn theo trục Y (trên - dưới)
	clamped_pos.y = clamp(player_pos.y, MAP_TOP_LIMIT, MAP_BOTTOM_LIMIT)

	# Áp dụng vị trí đã được giới hạn
	if clamped_pos != player_pos:
		player.global_position = clamped_pos

		# Dừng velocity nếu player chạm biên
		if clamped_pos.x != player_pos.x:
			player.velocity.x = 0
		if clamped_pos.y != player_pos.y:
			player.velocity.y = 0
