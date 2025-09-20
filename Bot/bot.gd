extends CharacterBody2D

# Bot states
enum BotState {
	IDLE,
	PATROLLING,
	CHASING,
	ATTACKING,
	RETURNING,
	DEAD,
	RESPAWNING
}

# Bot constants
const PATROL_SPEED = 50.0
const CHASE_SPEED = 120.0
const ATTACK_RANGE = 80.0
const DETECTION_RANGE = 200.0
const PATROL_RANGE = 300.0
const ATTACK_DAMAGE = 20
const ATTACK_COOLDOWN = 1.5
const RETURN_THRESHOLD = 400.0  # Khoảng cách tối đa từ vị trí spawn trước khi quay về

# Health system constants
const MAX_HEALTH = 100
const RESPAWN_TIME = 30.0

# Bot variables
var current_state = BotState.IDLE
var player_ref = null
var spawn_position: Vector2
var patrol_left_bound: float
var patrol_right_bound: float
var patrol_direction = 1  # 1 for right, -1 for left
var last_attack_time = 0.0
var state_timer = 0.0
var idle_duration = 2.0  # Thời gian đứng yên trước khi patrol

# Health system variables
var current_health = MAX_HEALTH
var respawn_timer = 0.0
var is_dead = false

# Node references
@onready var animated_sprite = $Container/AnimatedSprite2D
@onready var detection_area = $Area2D
@onready var collision_shape = $CollisionShape2D
@onready var attack_timer = Timer.new()
@onready var respawn_timer_node = Timer.new()

# Health bar nodes
var health_bar_container: Control
var health_bar_bg: ColorRect
var health_bar_fill: ColorRect
var target_indicator: Label

func _ready():
	# Thêm bot vào group để player có thể tìm thấy
	add_to_group("bots")

	# Lưu vị trí spawn
	spawn_position = global_position

	# Thiết lập patrol bounds
	patrol_left_bound = spawn_position.x - PATROL_RANGE / 2
	patrol_right_bound = spawn_position.x + PATROL_RANGE / 2

	# Thiết lập collision layers - Bot ở layer 3, không va chạm với player (layer 2)
	collision_layer = 4  # Layer 3 (bit 2)
	collision_mask = 1   # Chỉ va chạm với ground (layer 1)

	# Thiết lập attack timer
	add_child(attack_timer)
	attack_timer.wait_time = ATTACK_COOLDOWN
	attack_timer.one_shot = true

	# Thiết lập respawn timer
	add_child(respawn_timer_node)
	respawn_timer_node.wait_time = RESPAWN_TIME
	respawn_timer_node.one_shot = true
	respawn_timer_node.timeout.connect(_on_respawn_timer_timeout)

	# Bắt đầu với animation idle
	if animated_sprite:
		animated_sprite.play("idle")

	# Tạo health bar
	create_health_bar()

	print("Bot spawned at: ", spawn_position)

func _physics_process(delta):
	state_timer += delta

	# Nếu bot đã chết, không xử lý gì cả
	if current_state == BotState.DEAD:
		return

	# Tìm player nếu chưa có reference
	if not player_ref:
		find_player()

	# Xử lý state machine
	match current_state:
		BotState.IDLE:
			handle_idle_state(delta)
		BotState.PATROLLING:
			handle_patrol_state(delta)
		BotState.CHASING:
			handle_chase_state(delta)
		BotState.ATTACKING:
			handle_attack_state(delta)
		BotState.RETURNING:
			handle_return_state(delta)
		BotState.RESPAWNING:
			handle_respawn_state(delta)

	# Áp dụng gravity (chỉ khi không chết)
	if not is_on_floor() and current_state != BotState.DEAD:
		velocity += get_gravity() * delta

	# Di chuyển (chỉ khi không chết)
	if current_state != BotState.DEAD:
		move_and_slide()

	# Cập nhật animation và hướng
	update_animation_and_direction()

func find_player():
	# Tìm player trong scene
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
	else:
		# Fallback: tìm node có tên chứa "player" hoặc "Player"
		var all_nodes = get_tree().get_nodes_in_group("player")
		if all_nodes.size() == 0:
			# Tìm trong scene tree
			var scene_root = get_tree().current_scene
			player_ref = find_node_by_type(scene_root, "CharacterBody2D", "player")

func find_node_by_type(node: Node, type_name: String, name_contains: String = "") -> Node:
	if node.get_class() == type_name:
		if name_contains == "" or node.name.to_lower().contains(name_contains.to_lower()):
			return node

	for child in node.get_children():
		var result = find_node_by_type(child, type_name, name_contains)
		if result:
			return result

	return null

func handle_idle_state(delta):
	velocity.x = 0

	# Kiểm tra player trong tầm phát hiện
	if can_detect_player():
		change_state(BotState.CHASING)
		return

	# Chuyển sang patrol sau một thời gian
	if state_timer >= idle_duration:
		change_state(BotState.PATROLLING)

func handle_patrol_state(delta):
	# Kiểm tra player trong tầm phát hiện
	if can_detect_player():
		change_state(BotState.CHASING)
		return

	# Di chuyển patrol
	velocity.x = patrol_direction * PATROL_SPEED

	# Kiểm tra biên patrol
	if patrol_direction > 0 and global_position.x >= patrol_right_bound:
		patrol_direction = -1
		change_state(BotState.IDLE)  # Dừng một chút trước khi đổi hướng
	elif patrol_direction < 0 and global_position.x <= patrol_left_bound:
		patrol_direction = 1
		change_state(BotState.IDLE)  # Dừng một chút trước khi đổi hướng

func handle_chase_state(delta):
	if not player_ref:
		change_state(BotState.RETURNING)
		return

	var distance_to_player = global_position.distance_to(player_ref.global_position)

	# Kiểm tra nếu player quá xa spawn point
	var distance_to_spawn = global_position.distance_to(spawn_position)
	if distance_to_spawn > RETURN_THRESHOLD:
		change_state(BotState.RETURNING)
		return

	# Kiểm tra nếu player trong tầm tấn công
	if distance_to_player <= ATTACK_RANGE:
		change_state(BotState.ATTACKING)
		return

	# Kiểm tra nếu player ra khỏi tầm phát hiện
	if distance_to_player > DETECTION_RANGE:
		change_state(BotState.RETURNING)
		return

	# Di chuyển về phía player
	var direction = sign(player_ref.global_position.x - global_position.x)
	velocity.x = direction * CHASE_SPEED

func handle_attack_state(delta):
	velocity.x = 0  # Dừng lại khi tấn công

	if not player_ref:
		change_state(BotState.RETURNING)
		return

	var distance_to_player = global_position.distance_to(player_ref.global_position)

	# Nếu player ra khỏi tầm tấn công
	if distance_to_player > ATTACK_RANGE:
		change_state(BotState.CHASING)
		return

	# Thực hiện tấn công nếu cooldown đã hết
	if attack_timer.is_stopped():
		perform_attack()
		attack_timer.start()

func handle_return_state(delta):
	# Quay về vị trí spawn
	var distance_to_spawn = global_position.distance_to(spawn_position)

	if distance_to_spawn <= 50.0:  # Đã về gần spawn point
		change_state(BotState.IDLE)
		return

	# Di chuyển về spawn point
	var direction = sign(spawn_position.x - global_position.x)
	velocity.x = direction * PATROL_SPEED

func change_state(new_state: BotState):
	current_state = new_state
	state_timer = 0.0

	# Debug
	print("Bot state changed to: ", BotState.keys()[new_state])

func can_detect_player() -> bool:
	if not player_ref:
		return false

	var distance = global_position.distance_to(player_ref.global_position)
	return distance <= DETECTION_RANGE

func perform_attack():
	print("Bot attacks player!")

	# Có thể thêm damage cho player ở đây
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(ATTACK_DAMAGE)

func update_animation_and_direction():
	if not animated_sprite:
		return

	# Không cập nhật hướng khi chết
	if current_state != BotState.DEAD:
		# Cập nhật hướng nhìn
		if velocity.x > 0:
			animated_sprite.flip_h = false
		elif velocity.x < 0:
			animated_sprite.flip_h = true

	# Cập nhật animation dựa trên state
	match current_state:
		BotState.IDLE:
			animated_sprite.play("idle")
		BotState.PATROLLING, BotState.CHASING, BotState.RETURNING:
			animated_sprite.play("walking")
		BotState.ATTACKING:
			animated_sprite.play("dying")  # Tạm dùng dying làm attack animation
		BotState.DEAD:
			animated_sprite.play("dying")
		BotState.RESPAWNING:
			animated_sprite.play("idle")

func _on_area_2d_body_entered(body: Node2D) -> void:
	# Kiểm tra nếu là player
	if body.name.to_lower().contains("player") or body.is_in_group("player"):
		player_ref = body
		if current_state == BotState.IDLE or current_state == BotState.PATROLLING:
			change_state(BotState.CHASING)

func _on_area_2d_body_exited(body: Node2D) -> void:
	# Nếu player ra khỏi detection area và đang chase
	if body == player_ref and current_state == BotState.CHASING:
		# Kiểm tra khoảng cách thực tế trước khi chuyển state
		if global_position.distance_to(player_ref.global_position) > DETECTION_RANGE:
			change_state(BotState.RETURNING)

# Debug methods
func get_current_state() -> BotState:
	return current_state

func get_state_name() -> String:
	return BotState.keys()[current_state]

func get_distance_to_player() -> float:
	if player_ref:
		return global_position.distance_to(player_ref.global_position)
	return -1.0

func get_distance_to_spawn() -> float:
	return global_position.distance_to(spawn_position)

# Health system methods
func take_damage(damage: int):
	if current_state == BotState.DEAD:
		return

	current_health -= damage
	current_health = max(0, current_health)  # Không cho âm
	print("Bot nhận ", damage, " damage! Health còn: ", current_health)

	# Cập nhật health bar
	update_health_bar()

	# Hiệu ứng nhận damage
	if animated_sprite:
		animated_sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)

	# Chỉ chết khi hết máu hoàn toàn
	if current_health <= 0:
		die()

func die():
	print("Bot đã chết!")
	current_state = BotState.DEAD
	current_health = 0
	velocity = Vector2.ZERO

	# Tắt collision để player có thể đi qua
	if collision_shape:
		collision_shape.disabled = true

	# Tắt detection area
	if detection_area:
		detection_area.monitoring = false

	# Ẩn health bar và target indicator
	hide_health_bar()
	hide_target_indicator()

	# Chạy animation chết (không lặp)
	if animated_sprite:
		animated_sprite.play("dying")
		# Kết nối signal để dừng animation khi hoàn thành
		if not animated_sprite.animation_finished.is_connected(_on_death_animation_finished):
			animated_sprite.animation_finished.connect(_on_death_animation_finished)

	# Bắt đầu respawn timer
	respawn_timer_node.start()

func _on_death_animation_finished():
	# Dừng animation ở frame cuối
	if animated_sprite and current_state == BotState.DEAD:
		animated_sprite.stop()
		animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("dying") - 1

# Health bar methods
func create_health_bar():
	# Tạo container cho health bar
	health_bar_container = Control.new()
	health_bar_container.name = "HealthBarContainer"
	health_bar_container.position = Vector2(-30, -80)  # Trên đầu bot
	health_bar_container.size = Vector2(60, 8)
	add_child(health_bar_container)

	# Background của health bar
	health_bar_bg = ColorRect.new()
	health_bar_bg.name = "HealthBarBG"
	health_bar_bg.size = Vector2(60, 8)
	health_bar_bg.color = Color.BLACK
	health_bar_container.add_child(health_bar_bg)

	# Fill của health bar
	health_bar_fill = ColorRect.new()
	health_bar_fill.name = "HealthBarFill"
	health_bar_fill.size = Vector2(60, 8)
	health_bar_fill.color = Color.GREEN
	health_bar_container.add_child(health_bar_fill)

	# Target indicator (mũi tên)
	target_indicator = Label.new()
	target_indicator.name = "TargetIndicator"
	target_indicator.text = "↓"
	target_indicator.position = Vector2(25, -20)
	target_indicator.add_theme_color_override("font_color", Color.RED)
	target_indicator.visible = false
	health_bar_container.add_child(target_indicator)

func update_health_bar():
	if health_bar_fill and current_health >= 0:
		var health_percentage = float(current_health) / float(MAX_HEALTH)
		health_bar_fill.size.x = 60 * health_percentage

		# Đổi màu theo mức máu
		if health_percentage > 0.6:
			health_bar_fill.color = Color.GREEN
		elif health_percentage > 0.3:
			health_bar_fill.color = Color.YELLOW
		else:
			health_bar_fill.color = Color.RED

func show_target_indicator():
	if target_indicator:
		target_indicator.visible = true

func hide_target_indicator():
	if target_indicator:
		target_indicator.visible = false

func hide_health_bar():
	if health_bar_container:
		health_bar_container.visible = false

func show_health_bar():
	if health_bar_container:
		health_bar_container.visible = true

func handle_respawn_state(_delta):
	# Chờ respawn timer
	velocity = Vector2.ZERO

func _on_respawn_timer_timeout():
	respawn()

func respawn():
	print("Bot hồi sinh!")

	# Reset health
	current_health = MAX_HEALTH

	# Reset position về spawn point
	global_position = spawn_position

	# Bật lại collision
	if collision_shape:
		collision_shape.disabled = false

	# Bật lại detection area
	if detection_area:
		detection_area.monitoring = true

	# Reset về trạng thái idle
	change_state(BotState.IDLE)

	# Chạy animation idle
	if animated_sprite:
		animated_sprite.play("idle")
		animated_sprite.modulate = Color.WHITE

	# Reset health bar
	show_health_bar()
	update_health_bar()
	hide_target_indicator()
