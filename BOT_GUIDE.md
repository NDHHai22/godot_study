# Hướng dẫn sử dụng Bot AI với Combat System

## Tính năng Bot

Bot được tạo với hệ thống AI state machine và combat system có các tính năng sau:

### 1. **Tự động di chuyển (Patrol)**
- Bot sẽ tự động di chuyển qua lại trong khoảng 300 pixel từ vị trí spawn
- Khi đến biên, bot sẽ dừng lại một chút rồi đổi hướng
- Animation "walking" khi di chuyển, "idle" khi đứng yên

### 2. **Phát hiện Player**
- Tầm phát hiện: 200 pixel
- Khi player vào tầm phát hiện, bot sẽ chuyển sang chế độ đuổi theo
- Sử dụng Area2D để phát hiện player

### 3. **Đuổi theo Player (Chase)**
- Tốc độ đuổi: 120 pixel/giây (nhanh hơn patrol)
- Bot sẽ đuổi theo player cho đến khi:
  - Player ra khỏi tầm phát hiện (200 pixel)
  - Bot quá xa vị trí spawn (400 pixel)
  - Player vào tầm tấn công (80 pixel)

### 4. **Tấn công Player (Attack)**
- Tầm tấn công: 80 pixel
- Cooldown: 1.5 giây giữa các lần tấn công
- Damage: 20 điểm mỗi lần tấn công
- Bot sẽ dừng lại và tấn công khi player trong tầm

### 5. **Quay về vị trí spawn (Return)**
- Khi player ra khỏi tầm phát hiện hoặc bot quá xa spawn
- Bot sẽ quay về vị trí ban đầu với tốc độ patrol
- Khi về gần spawn (50 pixel), chuyển về chế độ idle

### 6. **Hệ thống máu và hồi sinh**
- Bot có 100 HP, player có 100 HP
- Bot chết khi HP = 0, sẽ hồi sinh sau 30 giây
- Khi chết, bot tắt collision để player đi qua được
- Hồi sinh tại vị trí spawn với full HP

### 7. **Player có thể tấn công Bot**
- Nhấn Space/Enter để tấn công
- Tầm tấn công: 100 pixel
- Damage: 50 điểm mỗi lần tấn công
- Cooldown: 0.8 giây giữa các lần tấn công

### 8. **Collision System**
- Player và Bot không va chạm với nhau (đi xuyên qua được)
- Cả hai chỉ va chạm với ground/platforms
- Bot tắt collision khi chết để player đi qua

## Cách sử dụng

### 1. **Thêm Bot vào Scene**
```gdscript
# Trong scene, thêm Bot.tscn
var bot_scene = preload("res://Bot/Bot.tscn")
var bot_instance = bot_scene.instantiate()
add_child(bot_instance)
bot_instance.global_position = Vector2(500, 300)  # Vị trí spawn
```

### 2. **Đảm bảo Player có Group**
Player phải được thêm vào group "player":
```gdscript
# Trong player script
func _ready():
    add_to_group("player")
```

### 3. **Combat Controls**
Player controls:
- **Tab**: Chọn bot gần nhất làm target (hiện mũi tên đỏ)
- **Space/Enter**:
  - Nếu có target: Tự động chạy đến và đánh target
  - Nếu không có target: Tấn công bot trong tầm
- **Arrow keys**: Di chuyển (sẽ dừng auto attack)
- **Up arrow**: Bay lên

### 4. **Combat Animations**
- **"slashing"**: Đứng yên tấn công
- **"run_slashing"**: Vừa chạy vừa tấn công
- **"running"**: Chạy bình thường
- **"idle"**: Đứng yên

### 5. **Target System**
- Nhấn Tab để chọn bot gần nhất
- Bot được chọn sẽ có mũi tên đỏ ↓ trên đầu
- Nhấn Space để tự động chạy đến và đánh target
- Di chuyển thủ công sẽ hủy auto attack
- Target tự động bỏ chọn khi bot chết

### 6. **Health System & UI**
- **Health Bar**: Hiển thị trên đầu mỗi bot
  - Xanh lá: > 60% HP
  - Vàng: 30-60% HP
  - Đỏ: < 30% HP
- **Target Indicator**: Mũi tên đỏ ↓ trên bot được chọn
- **Death Animation**: Không lặp lại, dừng ở frame cuối
- **Respawn**: Bot hồi sinh tại điểm spawn sau 30 giây

```gdscript
# Health constants
const MAX_HEALTH = 100  # Bot và Player
const RESPAWN_TIME = 30.0  # Bot respawn time
```

## Cấu hình Bot

Có thể điều chỉnh các thông số trong `Bot/bot.gd`:

```gdscript
# Tốc độ
const PATROL_SPEED = 50.0      # Tốc độ patrol
const CHASE_SPEED = 120.0      # Tốc độ đuổi theo

# Khoảng cách
const ATTACK_RANGE = 80.0      # Tầm tấn công
const DETECTION_RANGE = 200.0  # Tầm phát hiện
const PATROL_RANGE = 300.0     # Khoảng cách patrol
const RETURN_THRESHOLD = 400.0 # Khoảng cách tối đa từ spawn

# Tấn công
const ATTACK_DAMAGE = 20       # Damage mỗi lần tấn công
const ATTACK_COOLDOWN = 1.5    # Thời gian cooldown
```

## Animation

Bot sử dụng các animation sau:
- **"idle"**: Khi đứng yên
- **"walking"**: Khi di chuyển (patrol, chase, return)
- **"dying"**: Tạm thời dùng làm animation tấn công

## Debug

Để debug bot, sử dụng các method sau:
```gdscript
bot.get_state_name()           # Tên state hiện tại
bot.get_distance_to_player()   # Khoảng cách đến player
bot.get_distance_to_spawn()    # Khoảng cách đến spawn
```

## Test Scene

Sử dụng `test_bot.tscn` để test bot:
1. Mở scene test_bot.tscn
2. Chạy scene
3. Di chuyển player gần bot để test các tính năng
4. Xem console để theo dõi debug info
