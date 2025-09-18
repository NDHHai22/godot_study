extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -800.0
const FLY_SPEED = 300.0  # Tốc độ bay bằng tốc độ chạy
const FALL_DELAY = 0.5  # Thời gian delay trước khi rơi khi bay mà không di chuyển
const IDLE_BLINK_TIME = 3.0  # Thời gian đứng yên trước khi chớp mắt
const BLINK_DURATION = 1.5  # Thời gian chớp mắt
const BLINK_INTERVAL_MIN = 3.0  # Khoảng thời gian tối thiểu giữa các lần chớp mắt
const BLINK_INTERVAL_MAX = 5.0  # Khoảng thời gian tối đa giữa các lần chớp mắt

@onready var animated_sprite = $AnimatedSprite2D

# Biến trạng thái
var is_flying = false
var fall_timer = 0.0
var idle_timer = 0.0  # Timer cho hiệu ứng chớp mắt
var is_blinking = false  # Đang trong trạng thái chớp mắt
var next_blink_time = 0.0  # Thời gian cho lần chớp mắt tiếp theo
var last_direction = 1  # 1 for right, -1 for left

# One-way platform variables
var was_on_floor_last_frame = false
var platform_snap_distance = 10.0

func _ready():
	# Đặt animation mặc định
	animated_sprite.play("idle")
	# Thiết lập thời gian chớp mắt đầu tiên
	randomize()
	next_blink_time = randf_range(BLINK_INTERVAL_MIN, BLINK_INTERVAL_MAX)

func _physics_process(delta: float) -> void:
	# Lưu trạng thái floor trước khi xử lý
	was_on_floor_last_frame = is_on_floor()

	handle_input()
	handle_movement(delta)
	handle_one_way_platforms()
	handle_animations()
	move_and_slide()

func handle_input():
	# Handle flying - nhấn bất kỳ phím di chuyển nào khi không ở mặt đất để bay (trừ down)
	if not is_flying and not is_on_floor():
		if (Input.is_action_just_pressed("ui_up") or
			Input.is_action_just_pressed("ui_left") or
			Input.is_action_just_pressed("ui_right")):
			is_flying = true
			fall_timer = 0.0
			velocity.y = 0  # Dừng velocity để bay mượt mà

	# Nếu đang ở mặt đất và nhấn mũi tên lên thì bay luôn
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and not is_flying:
		is_flying = true
		fall_timer = 0.0
		velocity.y = 0

func handle_movement(delta: float):
	var direction := Input.get_axis("ui_left", "ui_right")

	# Cập nhật hướng nhìn
	if direction != 0:
		last_direction = direction
		animated_sprite.flip_h = direction < 0
		reset_idle_state()  # Reset idle state khi di chuyển

	if is_flying:
		handle_flying_movement(delta, direction)
	else:
		handle_ground_movement(delta, direction)

func handle_flying_movement(delta: float, direction: float):
	# Xử lý di chuyển khi bay (không có nút down)
	var vertical_input = 0.0
	if Input.is_action_pressed("ui_up"):
		vertical_input = -1.0
	# Loại bỏ ui_down - chỉ có thể bay lên hoặc thả để rơi tự nhiên

	# Di chuyển theo input
	velocity.x = direction * FLY_SPEED
	velocity.y = vertical_input * FLY_SPEED

	# Kiểm tra nếu không có input nào thì bắt đầu đếm thời gian rơi
	if direction == 0 and vertical_input == 0:
		fall_timer += delta
		if fall_timer >= FALL_DELAY:
			is_flying = false
			fall_timer = 0.0
	else:
		fall_timer = 0.0

func handle_ground_movement(delta: float, direction: float):
	# Add gravity when not flying
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle horizontal movement (không còn xử lý jump ở đây vì đã chuyển sang bay)
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func handle_animations():
	if is_flying:
		# Animation khi bay
		if fall_timer > 0.25:  # Gần rơi (nửa thời gian FALL_DELAY)
			animated_sprite.play("falling_down")
		else:
			animated_sprite.play("jump_loop")
	else:
		# Animation khi ở mặt đất
		if not is_on_floor():
			animated_sprite.play("falling_down")
		elif abs(velocity.x) > 10:
			animated_sprite.play("running")
			reset_idle_state()  # Reset idle state khi chạy
		else:
			# Đang đứng yên - xử lý chớp mắt
			handle_idle_blinking()

func reset_idle_state():
	idle_timer = 0.0
	is_blinking = false
	next_blink_time = randf_range(BLINK_INTERVAL_MIN, BLINK_INTERVAL_MAX)

func handle_idle_blinking():
	idle_timer += get_physics_process_delta_time()

	if not is_blinking:
		# Chưa chớp mắt, kiểm tra xem đã đến lúc chớp mắt chưa
		if idle_timer >= next_blink_time:
			is_blinking = true
			idle_timer = 0.0  # Reset timer để đếm thời gian chớp mắt
			animated_sprite.play("idle_blinking")
		else:
			animated_sprite.play("idle")
	else:
		# Đang chớp mắt, kiểm tra xem đã chớp đủ lâu chưa
		if idle_timer >= BLINK_DURATION:
			is_blinking = false
			idle_timer = 0.0  # Reset timer để đếm thời gian đến lần chớp mắt tiếp theo
			next_blink_time = randf_range(BLINK_INTERVAL_MIN, BLINK_INTERVAL_MAX)
			animated_sprite.play("idle")
		# Nếu chưa đủ thời gian thì tiếp tục chớp mắt

func handle_one_way_platforms():
	# Áp dụng one-way platform cho cả khi bay và khi không bay
	# Ngoại trừ khi đang rơi xuống trong chế độ bay

	var is_falling_while_flying = is_flying and fall_timer > 0

	# Nếu player đang di chuyển lên (velocity.y < 0) hoặc đang bay mà không rơi
	# thì tắt collision với platform
	if velocity.y < 0 or (is_flying and not is_falling_while_flying):
		# Tắt collision với tilemap layer
		set_collision_mask_value(1, false)
	else:
		# Khi player đang rơi xuống (velocity.y >= 0) hoặc đang rơi trong chế độ bay
		# bật lại collision
		set_collision_mask_value(1, true)

		# Kiểm tra xem có cần "snap" xuống platform không
		# Điều này giúp player đứng trên platform một cách mượt mà
		if not was_on_floor_last_frame and is_on_floor():
			# Player vừa mới chạm platform, snap xuống để đảm bảo đứng vững
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsRayQueryParameters2D.create(
				global_position,
				global_position + Vector2(0, platform_snap_distance)
			)
			query.collision_mask = 1  # Chỉ check với tilemap layer
			var result = space_state.intersect_ray(query)

			if result:
				# Snap player xuống platform
				global_position.y = result.position.y
