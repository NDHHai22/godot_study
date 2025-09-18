extends Node2D

# Giới hạn map (có thể điều chỉnh theo ý muốn)
const MAP_LEFT_LIMIT = 0
const MAP_RIGHT_LIMIT = 3000.0
const MAP_TOP_LIMIT = 0
const MAP_BOTTOM_LIMIT = 1000.0

@onready var player = $CharacterBody2D

# Flag để đảm bảo camera limits chỉ được set một lần
var camera_limits_initialized = false

func _ready() -> void:
	# Kết nối signal từ player
	if player:
		player.player_ready.connect(_on_player_ready)
	else:
		# Fallback nếu player chưa sẵn sàng
		call_deferred("setup_camera_limits")

func _on_player_ready():
	print("Player ready signal received!")
	setup_camera_limits()

func _physics_process(_delta):
	# Force update camera limits nếu chưa được thiết lập
	if not camera_limits_initialized and player and player.has_node("Camera2D"):
		print("Force updating camera limits in _physics_process")
		var camera = player.get_node("Camera2D")
		camera.limit_left = MAP_LEFT_LIMIT
		camera.limit_right = MAP_RIGHT_LIMIT
		camera.limit_top = MAP_TOP_LIMIT
		camera.limit_bottom = MAP_BOTTOM_LIMIT
		camera.limit_smoothed = true
		camera.enabled = true
		camera.make_current()
		camera_limits_initialized = true
		print("Camera limits force updated: Left=", MAP_LEFT_LIMIT, ", Right=", MAP_RIGHT_LIMIT, ", Top=", MAP_TOP_LIMIT, ", Bottom=", MAP_BOTTOM_LIMIT)

	# Giới hạn player position trong map bounds
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

func setup_camera_limits():
	print("=== SETUP CAMERA LIMITS ===")
	print("Player found: ", player != null)

	if not player:
		print("ERROR: Player not found!")
		return

	print("Player has set_camera_limits method: ", player.has_method("set_camera_limits"))
	print("Player has Camera2D node: ", player.has_node("Camera2D"))

	if player.has_method("set_camera_limits"):
		# Sử dụng hàm của player để thiết lập camera limits
		print("Using player.set_camera_limits method")
		player.set_camera_limits(MAP_LEFT_LIMIT, MAP_RIGHT_LIMIT, MAP_TOP_LIMIT, MAP_BOTTOM_LIMIT)
	elif player.has_node("Camera2D"):
		# Fallback: thiết lập trực tiếp nếu hàm không tồn tại
		print("Using fallback method - direct camera access")
		var camera = player.get_node("Camera2D")
		camera.limit_left = MAP_LEFT_LIMIT
		camera.limit_right = MAP_RIGHT_LIMIT
		camera.limit_top = MAP_TOP_LIMIT
		camera.limit_bottom = MAP_BOTTOM_LIMIT
		camera.limit_smoothed = true
		print("Camera limits đã được thiết lập (fallback): Left=", MAP_LEFT_LIMIT, ", Right=", MAP_RIGHT_LIMIT, ", Top=", MAP_TOP_LIMIT, ", Bottom=", MAP_BOTTOM_LIMIT)
	else:
		print("ERROR: Cannot set camera limits - no method or camera found!")

	# Verify the limits were set correctly
	if player.has_node("Camera2D"):
		var camera = player.get_node("Camera2D")
		print("=== VERIFICATION ===")
		print("Current camera limits: Left=", camera.limit_left, ", Right=", camera.limit_right, ", Top=", camera.limit_top, ", Bottom=", camera.limit_bottom)
		camera_limits_initialized = true

# Hàm để thay đổi giới hạn map trong runtime
func update_map_limits(left: float, right: float, top: float, bottom: float):
	# Cập nhật constants (chỉ có thể thay đổi trong runtime, không thay đổi const)
	# Thay vào đó, ta sẽ cập nhật trực tiếp camera
	if player and player.has_method("set_camera_limits"):
		player.set_camera_limits(left, right, top, bottom)
		print("Map limits đã được cập nhật: Left=", left, ", Right=", right, ", Top=", top, ", Bottom=", bottom)

# Hàm để force update camera limits (có thể gọi từ debug hoặc UI)
func force_update_camera_limits():
	print("=== FORCE UPDATE CAMERA LIMITS ===")
	setup_camera_limits()

# Hàm để kiểm tra trạng thái camera hiện tại
func check_camera_status():
	print("=== CAMERA STATUS CHECK ===")
	if player and player.has_node("Camera2D"):
		var camera = player.get_node("Camera2D")
		print("Camera enabled: ", camera.enabled)
		print("Camera current: ", camera.is_current())
		print("Camera limits: Left=", camera.limit_left, ", Right=", camera.limit_right, ", Top=", camera.limit_top, ", Bottom=", camera.limit_bottom)
		print("Camera position: ", camera.global_position)
		print("Player position: ", player.global_position)
	else:
		print("Camera not found!")

# Input handling để test camera
func _input(event):
	# Debug keys
	if event.is_action_pressed("ui_accept"):  # Enter key
		print("=== MANUAL CAMERA LIMITS UPDATE ===")
		force_update_camera_limits()
	elif event.is_action_pressed("ui_select"):  # Space key
		check_camera_status()
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		# Test với limits khác
		print("=== TESTING DIFFERENT LIMITS ===")
		update_map_limits(100, 2500, 50, 800)
