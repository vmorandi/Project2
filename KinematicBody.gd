extends KinematicBody

export var strafe = true

signal coin_collected

var gravity = -9.8 * 3
var velocity = Vector3()
var camera
var jumps = 2
var prev_collided = false
var coin_count = 0
var in_ledge = false
var sfx = 1;

const SPEED = 10
const ACCELERATION = 8
const DE_ACCELERATION = 14

func _ready():
	camera = get_node("../OuterGimbal/InnerGimbal/Camera").get_global_transform()
	get_parent().get_parent().get_child(0).get_child(2).connect("hit_floor", self, "hit_floor_received")
	get_parent().get_parent().get_child(1).get_child(2).connect("hit_floor", self, "hit_floor_received")
	get_parent().get_parent().get_child(2).get_child(2).connect("hit_floor", self, "hit_floor_received")
	get_parent().get_parent().get_child(3).get_child(2).connect("hit_floor", self, "hit_floor_received")
	
	# sphere floor
	get_parent().get_parent().get_child(4).get_child(1).connect("hit_floor", self, "hit_floor_received")
	
	get_parent().get_parent().get_child(0).get_child(3).get_child(0).get_child(1).connect("coin_touched", self, "collect_coin")
	get_parent().get_parent().get_child(1).get_child(3).get_child(0).get_child(1).connect("coin_touched", self, "collect_coin")
	get_parent().get_parent().get_child(2).get_child(3).get_child(0).get_child(1).connect("coin_touched", self, "collect_coin")
	get_parent().get_parent().get_child(3).get_child(3).get_child(0).get_child(1).connect("coin_touched", self, "collect_coin")
	
	get_parent().get_parent().get_child(1).get_child(4).connect("hit_ledge", self, "hit_ledge_received")
	get_parent().get_parent().get_child(1).get_child(4).connect("leave_ledge", self, "leave_ledge_received")

func hit_floor_received():
	jumps = 2
	
var first = true
func hit_ledge_received():
	if first:
		first = false
	else:
		in_ledge = true
	
func leave_ledge_received():
	in_ledge = false
	gravity = -9.8 * 3

func collect_coin():
	coin_count += 1
	emit_signal("coin_collected", coin_count)

func _process(delta):
	if Input.is_key_pressed(KEY_COMMA):
		get_parent().get_node("AudioStreamPlayer3D").stop()
	if Input.is_key_pressed(KEY_PERIOD):
		get_parent().get_node("AudioStreamPlayer3D").play(0)
	if Input.is_key_pressed(KEY_N):
		sfx = 0;
	if Input.is_key_pressed(KEY_M):
		sfx = 1;
	if translation.y < -20:
		get_tree().change_scene("res://GameOverScreen.tscn")
		
func _physics_process(delta):
	var dir = Vector3()
	
	# adding "and is_on_floor()" will disable air movement
	if not is_on_wall():
		if Input.is_action_pressed("ui_up"):
			dir -= camera.basis[2]
		if Input.is_action_pressed("ui_down"):
			dir += camera.basis[2]
		if strafe:
			if Input.is_action_pressed("ui_left"):
				dir -= camera.basis[0]
			if Input.is_action_pressed("ui_right"):
				dir += camera.basis[0]
		else:
			if Input.is_action_pressed("ui_left"):
				rotation.y += delta
			elif Input.is_action_pressed("ui_right"):
				rotation.y -= delta
	
		
	dir.y = 0
	dir = dir.rotated(Vector3(0, 1, 0), rotation.y)
	dir = dir.normalized()
	
	var hv = velocity
	hv.y = 0
	
	if Input.is_action_just_pressed("ui_space") and jumps > 0:
		if(sfx > 0):
			get_parent().get_node("Jump").play(0)
		jumps = jumps - 1
		velocity.y = 10
	elif velocity.y < -SPEED / 2 and Input.is_action_pressed("ui_glide"):
		velocity.y = -SPEED / 2
	else:
		velocity.y += delta * gravity
	
	var new_pos = dir * SPEED
	var accel = DE_ACCELERATION
	
	if dir.dot(hv) > 0:
		accel = ACCELERATION
	
	hv = hv.linear_interpolate(new_pos, accel * delta)
	
	velocity.x = hv.x
	velocity.z = hv.z
	
	if Input.is_action_pressed("ui_shift") and not Input.is_action_pressed("ui_space"):
		if in_ledge:
			gravity = 0
			velocity = Vector3(0, 0, 0)
			jumps = 2
		else:
			gravity = -9.8 * 3
			var kc = move_and_collide(velocity, true, true, true)
			var collided = is_instance_valid(kc)
			if not collided and prev_collided:
				velocity = Vector3(0, 0, 0)
			else:
				velocity = move_and_slide(velocity, Vector3(0, 1, 0))
				prev_collided = collided
	else:
		var kc = move_and_collide(velocity, true, true, true)
		if is_instance_valid(kc):
			velocity = move_and_slide(velocity, Vector3(0, 1, 0), false, 4, deg2rad(20))
		else:
			velocity = move_and_slide(velocity, Vector3(0, 1, 0))
