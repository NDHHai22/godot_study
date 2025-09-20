extends CharacterBody2D

# Signal để thông báo khi player đã sẵn sàng
signal player_ready

const SPEED = 300.0
const JUMP_VELOCITY = -800.0
const FLY_SPEED = 300.0  # Tốc độ bay bằng tốc độ chạy
const FALL_DELAY = 0.5  # Thời gian delay trước khi rơi khi bay mà không di chuyển
const IDLE_BLINK_TIME = 3.0  # Thời gian đứng yên trước khi chớp mắt
const BLINK_DURATION = 1.5  # Thời gian chớp mắt
const BLINK_INTERVAL_MIN = 3.0  # Khoảng thời gian tối thiểu giữa các lần chớp mắt
const BLINK_INTERVAL_MAX = 5.0  # Khoảng thời gian tối đa giữa các lần chớp mắt

# Combat constants
const ATTACK_DAMAGE = 50
const ATTACK_RANGE = 100.0
const ATTACK_COOLDOWN = 0.8
const MAX_HEALTH = 100

@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = $Camera2D

# Biến trạng thái
var is_flying = false
var fall_timer = 0.0
var idle_timer = 0.0  # Timer cho hiệu ứng chớp mắt
var is_blinking = false  # Đang trong trạng thái chớp mắt
var next_blink_time = 0.0  # Thời gian cho lần chớp mắt tiếp theo
var last_direction = 1  # 1 for right, -1 for left

# Combat variables
var current_health = MAX_HEALTH
var is_attacking = false
var attack_timer = 0.0
var can_attack = true

# Target system variables
var selected_target = null
var auto_attacking = false
var move_to_target = false

# Click system variables
var last_clicked_bot = null
var last_click_time = 0.0
var double_click_time = 0.5  # Thời gian tối đa giữa 2 click để tính là double click

# One-way platform variables
var was_on_floor_last_frame = false
var platform_snap_distance = 10.0

# Camera settings
var camera_smoothing_speed = 5.0
var camera_offset = Vector2.ZERO  # Offset cho camera nếu cần

func _ready():
	# Thêm player vào group để bot có thể phát hiện
	add_to_group("player")

	# Thiết lập collision layers - Player ở layer 2, không va chạm với bot (layer 3)
	collision_layer = 2  # Layer 2 (bit 1)
	collision_mask = 1   # Chỉ va chạm với ground (layer 1)

	# Đặt animation mặc định
	animated_sprite.play("idle")
	# Thiết lập thời gian chớp mắt đầu tiên
	randomize()
	next_blink_time = randf_range(BLINK_INTERVAL_MIN, BLINK_INTERVAL_MAX)

	# Thiết lập camera để theo dõi player
	setup_camera()

	# Emit signal để thông báo player đã sẵn sàng
	player_ready.emit()

func setup_camera():
	if camera:
		# Kích hoạt camera
		camera.enabled = true
		camera.make_current()

		# Thiết lập smooth movement cho camera
		camera.position_smoothing_enabled = false
		camera.position_smoothing_speed = camera_smoothing_speed

		# Đảm bảo camera limit smoothing được bật
		camera.limit_smoothed = true

		# Thiết lập offset nếu có
		camera.offset = camera_offset

		print("Camera đã được thiết lập và kích hoạt với smoothing speed: ", camera_smoothing_speed)

# Hàm để cập nhật giới hạn camera từ bên ngoài
func set_camera_limits(left: int, right: int, top: int, bottom: int):
	print("=== PLAYER SET_CAMERA_LIMITS CALLED ===")
	print("Parameters: Left=", left, ", Right=", right, ", Top=", top, ", Bottom=", bottom)
	print("Camera exists: ", camera != null)

	if camera:
		print("Setting camera limits...")
		camera.limit_left = left
		camera.limit_right = right
		camera.limit_top = top
		camera.limit_bottom = bottom
		print("Camera limits đã được cập nhật: Left=", left, ", Right=", right, ", Top=", top, ", Bottom=", bottom)

		# Verify the limits were actually set
		print("Verification - Current limits: Left=", camera.limit_left, ", Right=", camera.limit_right, ", Top=", camera.limit_top, ", Bottom=", camera.limit_bottom)
	else:
		print("ERROR: Camera not found in set_camera_limits!")

# Hàm để điều chỉnh camera settings
func set_camera_smoothing(speed: float):
	camera_smoothing_speed = speed
	if camera:
		camera.position_smoothing_speed = speed
		print("Camera smoothing speed đã được cập nhật: ", speed)

func set_camera_offset(offset: Vector2):
	camera_offset = offset
	if camera:
		camera.offset = offset
		print("Camera offset đã được cập nhật: ", offset)

func _physics_process(delta: float) -> void:
	# Lưu trạng thái floor trước khi xử lý
	was_on_floor_last_frame = is_on_floor()

	# Xử lý attack timer
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
			is_attacking = false

	# Kiểm tra target còn hợp lệ không
	if selected_target and (not is_instance_valid(selected_target) or selected_target.current_state == selected_target.BotState.DEAD):
		stop_auto_attack()

	handle_input()
	handle_movement(delta)
	handle_one_way_platforms()
	handle_animations()
	move_and_slide()

func handle_input():
	# Handle target selection - Tab để chọn target
	if Input.is_action_just_pressed("ui_cancel"):  # Tab key
		select_nearest_target()

	# Handle attack - Space hoặc Enter để tấn công
	if Input.is_action_just_pressed("ui_accept"):
		if selected_target and selected_target.current_state != selected_target.BotState.DEAD:
			# Bắt đầu auto attack target
			start_auto_attack()
		elif can_attack and not is_attacking:
			# Tấn công thường
			perform_attack()

	# Kiểm tra di chuyển để dừng auto attack
	var movement_input = Input.get_axis("ui_left", "ui_right")
	if movement_input != 0 and auto_attacking:
		stop_auto_attack()

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

	# Xử lý auto attack movement
	if auto_attacking and selected_target and selected_target.current_state != selected_target.BotState.DEAD:
		handle_auto_attack_movement(delta)
		return

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
	# Ưu tiên animation tấn công
	if is_attacking:
		if abs(velocity.x) > 10:
			# Đang chạy và tấn công
			animated_sprite.play("run_slashing")
		else:
			# Đứng yên và tấn công
			animated_sprite.play("slashing")
		return

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

# Combat methods
func perform_attack():
	if not can_attack or is_attacking:
		return

	print("Player tấn công!")
	is_attacking = true
	can_attack = false
	attack_timer = ATTACK_COOLDOWN

	# Ưu tiên tấn công target đã chọn
	if selected_target and selected_target.current_state != selected_target.BotState.DEAD:
		var distance_to_target = global_position.distance_to(selected_target.global_position)
		if distance_to_target <= ATTACK_RANGE:
			if selected_target.has_method("take_damage"):
				selected_target.take_damage(ATTACK_DAMAGE)
				print("Đánh trúng target!")
				return

	# Nếu không có target hoặc target ngoài tầm, tìm bot gần nhất
	var bots_in_range = find_bots_in_attack_range()
	for bot in bots_in_range:
		if bot.has_method("take_damage"):
			bot.take_damage(ATTACK_DAMAGE)
			print("Đánh trúng bot!")
			break  # Chỉ đánh một con

func find_bots_in_attack_range() -> Array:
	var bots = []
	var all_bots = get_tree().get_nodes_in_group("bots")

	for bot in all_bots:
		var distance = global_position.distance_to(bot.global_position)
		if distance <= ATTACK_RANGE:
			bots.append(bot)

	return bots

# Hàm nhận damage từ bot
func take_damage(damage: int):
	current_health -= damage
	print("Player nhận ", damage, " damage từ bot! Health còn: ", current_health)

	# Hiệu ứng nhận damage
	if animated_sprite:
		animated_sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)

	if current_health <= 0:
		die()

func die():
	print("Player đã chết!")
	# Dừng auto attack khi chết
	stop_auto_attack()
	# Có thể thêm logic respawn cho player ở đây

# Target system methods
func select_nearest_target():
	var bots = get_tree().get_nodes_in_group("bots")
	var nearest_bot = null
	var nearest_distance = 999999.0

	for bot in bots:
		if bot.current_state != bot.BotState.DEAD:
			var distance = global_position.distance_to(bot.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_bot = bot

	# Bỏ chọn target cũ
	if selected_target and selected_target.has_method("hide_target_indicator"):
		selected_target.hide_target_indicator()

	# Chọn target mới
	selected_target = nearest_bot
	if selected_target and selected_target.has_method("show_target_indicator"):
		selected_target.show_target_indicator()
		print("Đã chọn target: ", selected_target.name)

func start_auto_attack():
	if not selected_target:
		return

	auto_attacking = true
	move_to_target = true
	print("Bắt đầu auto attack target!")

func stop_auto_attack():
	auto_attacking = false
	move_to_target = false

	# Bỏ chọn target
	if selected_target and selected_target.has_method("hide_target_indicator"):
		selected_target.hide_target_indicator()
	selected_target = null
	print("Dừng auto attack!")

func handle_auto_attack_movement(delta: float):
	if not selected_target or selected_target.current_state == selected_target.BotState.DEAD:
		stop_auto_attack()
		return

	var distance_to_target = global_position.distance_to(selected_target.global_position)

	# Nếu đủ gần để tấn công
	if distance_to_target <= ATTACK_RANGE:
		move_to_target = false
		# Tấn công nếu có thể
		if can_attack and not is_attacking:
			perform_attack()
	else:
		# Di chuyển về phía target
		move_to_target = true
		var direction = sign(selected_target.global_position.x - global_position.x)

		# Cập nhật hướng nhìn
		last_direction = direction
		animated_sprite.flip_h = direction < 0

		# Di chuyển
		if is_flying:
			velocity.x = direction * FLY_SPEED
		else:
			velocity.x = direction * SPEED
			# Áp dụng gravity
			if not is_on_floor():
				velocity += get_gravity() * delta

# Click system methods
func on_bot_clicked(bot):
	if not bot or bot.current_state == bot.BotState.DEAD:
		return

	# Sử dụng Time.get_time_dict_from_system() để lấy thời gian hiện tại
	var time_stamp = Time.get_time_dict_from_system()
	var current_time_ms = time_stamp.hour * 3600000 + time_stamp.minute * 60000 + time_stamp.second * 1000

	# Kiểm tra double click
	if last_clicked_bot == bot and (current_time_ms - last_click_time) <= (double_click_time * 1000):
		# Double click - bắt đầu auto attack
		print("Double click trên bot - bắt đầu auto attack!")
		set_target_and_auto_attack(bot)
	else:
		# Single click - chỉ chọn target
		print("Single click trên bot - chọn làm target")
		select_target(bot)

	# Cập nhật thông tin click
	last_clicked_bot = bot
	last_click_time = current_time_ms

func select_target(bot):
	# Bỏ chọn target cũ
	if selected_target and selected_target.has_method("hide_target_indicator"):
		selected_target.hide_target_indicator()

	# Chọn target mới
	selected_target = bot
	if selected_target and selected_target.has_method("show_target_indicator"):
		selected_target.show_target_indicator()
		print("Đã chọn target: ", selected_target.name)

func set_target_and_auto_attack(bot):
	select_target(bot)
	start_auto_attack()
