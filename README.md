# Game Platformer 2D - Fallen Angels

Một game 2D platformer được phát triển bằng Godot Engine 4.4, có nhân vật chính là thiên thần sa ngã với nhiều animation phong phú và gameplay hấp dẫn.

## 📖 Mô tả dự án

Game là một platformer 2D với nhân vật chính "Fallen Angels" có thể thực hiện nhiều hành động khác nhau như chạy, nhảy, tấn công, và nhiều kỹ năng chiến đấu. Game có hệ thống tile-based level design với nền tảng đa lớp tạo hiệu ứng thị giác sâu.

## 🎮 Tính năng game

### Nhân vật chính (Fallen Angels)
- **Idle & Idle Blinking**: Trạng thái chờ với animation chớp mắt
- **Movement**: Di chuyển qua lại (Walking/Running)
- **Combat System**: 
  - Slashing (Chém cận chiến)
  - Slashing in The Air (Chém trên không)
  - Kicking (Đá)
  - Throwing (Ném đạn)
  - Run Slashing/Throwing (Tấn công khi chạy)
- **Acrobatics**:
  - Jump Start (Bắt đầu nhảy)
  - Jump Loop (Nhảy liên tục)
  - Falling Down (Rơi xuống)
  - Sliding (Trượt)
- **Status Effects**:
  - Hurt (Bị thương)
  - Dying (Chết)

### Hệ thống điều khiển
- **A/D hoặc ←/→**: Di chuyển trái/phải
- **Space/↑**: Nhảy
- **Tốc độ di chuyển**: 300 pixels/giây
- **Lực nhảy**: -800 pixels/giây

### Thiết kế level
- **Parallax Background**: Nhiều lớp nền tạo hiệu ứng chiều sâu
  - Layer 1: Sky background
  - Layer 2: Clouds
  - Layer 3: Mountains
  - Layer 4-6: Forest layers
  - Layer 7: Walking platform
  - Layer 8: Foreground
- **Tilemap System**: Sử dụng Ground_Platforms.png cho nền tảng
- **Physics-based collision**: Hệ thống va chạm dựa trên vật lý

## 🛠️ Công nghệ sử dụng

- **Engine**: Godot 4.4
- **Rendering**: GL Compatibility (tương thích với nhiều thiết bị)
- **Language**: GDScript
- **Resolution**: Canvas items scaling
- **Art Style**: Pixel art 2D

## 📁 Cấu trúc dự án

```
base/
├── main.gd/tscn          # Menu chính với nút Play/Quit
├── world.gd/tscn         # Scene game chính
├── project.godot         # File cấu hình Godot
├── Player/
│   ├── player.gd         # Script điều khiển nhân vật
│   └── Player.tscn       # Scene nhân vật với animation
├── Assets/
│   ├── Map/              # Background layers (8 layers)
│   ├── Player/           # Sprites nhân vật Fallen Angels
│   │   └── Fallen_Angels/
│   │       ├── Fallen_Angels_1/
│   │       ├── Fallen_Angels_2/
│   │       └── Fallen_Angels_3/    # Bộ sprite đang sử dụng
│   │           ├── Dying/
│   │           ├── Falling Down/
│   │           ├── Hurt/
│   │           ├── Idle/
│   │           ├── Idle Blinking/
│   │           ├── Jump Loop/
│   │           ├── Jump Start/
│   │           ├── Kicking/
│   │           ├── Run Slashing/
│   │           ├── Run Throwing/
│   │           ├── Running/
│   │           ├── Slashing/
│   │           ├── Slashing in The Air/
│   │           ├── Sliding/
│   │           ├── Throwing/
│   │           ├── Throwing in The Air/
│   │           └── Walking/
│   └── Tile/
│       └── Ground_Platforms.png    # Tileset cho nền tảng
```

## 🚀 Cách chạy game

1. **Yêu cầu hệ thống:**
   - Godot Engine 4.4+
   - OpenGL compatible graphics

2. **Chạy từ Godot Editor:**
   ```bash
   # Mở Godot Engine
   # Import project từ thư mục base/
   # Nhấn F5 hoặc Play button
   ```

3. **Build game:**
   - Trong Godot: Project → Export
   - Chọn platform muốn build (Windows/Linux/Mac/Mobile)

## 🎯 Gameplay

1. **Menu chính**: Chọn "Chơi" để bắt đầu hoặc "Thoát" để thoát game
2. **Di chuyển**: Sử dụng phím mũi tên hoặc WASD
3. **Nhảy**: Space hoặc mũi tên lên
4. **Mục tiêu**: Khám phá level và thử nghiệm các kỹ năng của nhân vật

## 🔧 Phát triển

### Animation System
- Sử dụng AnimatedSprite2D với SpriteFrames
- 24 FPS cho tất cả animation
- Scale 0.147778 để phù hợp với game size

### Physics
- CharacterBody2D với collision detection
- Gravity system tự động
- Move and slide cho movement mượt mà

### Camera System
- **Auto-follow camera** theo nhân vật với smooth movement
- **Map limits** tự động giới hạn camera theo kích thước map (0-3000x, 0-1000y)
- **Position smoothing** với tốc độ có thể điều chỉnh (mặc định: 5.0)
- **Limit smoothing** để tránh camera bị giật khi chạm biên
- **Camera offset** có thể điều chỉnh cho cinematic effects

## 🎨 Art Assets

Game sử dụng bộ sprite "Fallen Angels" với 3 variant khác nhau, hiện tại đang sử dụng Fallen_Angels_3. Mỗi character có đầy đủ animation cho mọi hành động từ idle đến combat.

Background được thiết kế theo phong cách parallax với 8 layer khác nhau tạo chiều sâu cho game world.

## 📝 Roadmap

### ✅ Completed
- [x] **Camera System**: Auto-follow camera với map limits và smooth movement
- [x] **Player Movement**: Bay, chạy, nhảy với animation system hoàn chỉnh
- [x] **One-way Platforms**: Hệ thống platform có thể đi qua từ dưới lên

### 🚧 In Progress
- [ ] Thêm enemy và AI system
- [ ] Implement combat mechanics

### 📋 Planned
- [ ] Level design nâng cao với multiple areas
- [ ] Sound effects và background music
- [ ] Power-ups và items system
- [ ] Story mode với cutscenes
- [ ] Multiple levels với different themes
- [ ] Save/Load system
- [ ] Camera effects (shake, zoom, cinematic)
- [ ] Dynamic camera limits dựa trên areas

## 🤝 Đóng góp

Đây là dự án học tập/phát triển cá nhân. Mọi góp ý và đóng góp đều được hoan nghênh!

## 📄 License

Project này được phát triển cho mục đích học tập và thử nghiệm.

---

**Made with ❤️ using Godot Engine**
