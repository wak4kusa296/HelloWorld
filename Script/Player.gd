extends CharacterBody2D

@export var speed: float = 400.0
# 振り向きの滑らかさ
@export var turn_speed: float = 10.0

@onready var anim = $AnimatedSprite2D
@onready var nav_agent = $NavigationAgent2D

# 見た目の向き
var visual_direction: Vector2 = Vector2.DOWN

func _ready():
	# 【重要】Godot 4.3+ の場合、ナビゲーションの初期化待ちとして1フレーム待つおまじない
	# これがないと開始直後にエラーが出ることがある
	await get_tree().physics_frame
	
	# 必要なら初期座標セット
	nav_agent.target_position = global_position

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		nav_agent.target_position = get_global_mouse_position()
	elif event is InputEventScreenTouch and event.pressed:
		nav_agent.target_position = get_canvas_transform().affine_inverse() * event.position

func _physics_process(delta):
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		var suffix = get_direction_name(visual_direction)
		anim.play("Idle-" + suffix)
		return

	# --- 移動処理 ---
	var current_pos = global_position
	var next_pos = nav_agent.get_next_path_position()
	
	# 経路に沿った移動方向
	var move_direction = current_pos.direction_to(next_pos)
	
	# 移動実行 (move_and_slideだけで自動的に補間されるのでシンプルに)
	velocity = move_direction * speed
	move_and_slide()

	# --- アニメーション向き処理 (ここは演出なので手動計算) ---
	# 移動していれば、見た目の向きをそちらへ回転させる
	if velocity.length() > 0:
		visual_direction = visual_direction.slerp(move_direction, turn_speed * delta)
	
	var suffix = get_direction_name(visual_direction)
	anim.play("Move-" + suffix)

func get_direction_name(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "D" if dir.x > 0 else "A"
	else:
		return "S" if dir.y > 0 else "W"
