extends CharacterBody3D

# --- COMPONENTS ---
@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree
@onready var ai_controller = $AIController3D

# --- SETTINGS ---
var speed = 4.0

# --- STATE ---
var is_locked = false # True when attacking
var frame_skip = randi() % 4 # Optimization

func _ready():
	# 1. Initialize the AI (This connects the Body to the Brain)
	ai_controller.init(self)
	
	# 2. Setup Navigation
	nav_agent.velocity_computed.connect(_move_with_avoidance)

func _physics_process(delta):
	# AI Controller automatically calls set_action(), so we don't call it here.

	# 1. OPTIMIZATION
	frame_skip += 1
	if frame_skip % 4 != 0:
		move_and_slide()
		return

	# 2. IF LOCKED (Attacking), STOP MOVING
	if is_locked:
		move_and_slide()
		return

	# 3. MOVEMENT LOGIC
	if not nav_agent.is_navigation_finished():
		var next_pos = nav_agent.get_next_path_position()
		var dir = global_position.direction_to(next_pos)
		
		# Direct Movement (Fix for stuck enemies)
		velocity = dir * speed
		move_and_slide()
		
		# Rotation
		if velocity.length() > 0.1:
			var target_rot = atan2(velocity.x, velocity.z)
			rotation.y = lerp_angle(rotation.y, target_rot, 0.1)
		
		# Animation
		anim_tree.set("parameters/conditions/is_moving", true)
		anim_tree.set("parameters/conditions/is_idle", false)
	else:
		velocity = Vector3.ZERO
		move_and_slide()
		anim_tree.set("parameters/conditions/is_moving", false)
		anim_tree.set("parameters/conditions/is_idle", true)

# --- 🧠 AI INTERFACE (REQUIRED FUNCTIONS) ---

# 1. INPUTS: What the AI sees
func get_obs() -> Dictionary:
	var obs = []
	var player = get_tree().get_first_node_in_group("Player")
	
	if player:
		# Distance to player
		obs.append(global_position.distance_to(player.global_position))
		# Direction to player (Relative)
		var to_player = global_position.direction_to(player.global_position)
		obs.append(to_player.x)
		obs.append(to_player.z)
	else:
		obs.append(0.0)
		obs.append(0.0)
		obs.append(0.0)
		
	return {"obs": obs}

# 2. REWARDS: How the AI learns
func get_reward() -> float:
	var reward = 0.0
	var player = get_tree().get_first_node_in_group("Player")
	
	if player:
		var dist = global_position.distance_to(player.global_position)
		# Reward for getting close (Closer = Higher reward)
		if dist < 2.0:
			reward += 0.1
		else:
			reward -= 0.01 # Small penalty for being far away
			
	return reward

# 3. ACTIONS: What the AI can do
func get_action_space() -> Dictionary:
	return {
		"action_type": "discrete",
		"size": 3 # 0=Idle, 1=Chase, 2=Attack
	}

# 4. ACTION HANDLER: Performing the chosen action
func set_action(action_id):
	if is_locked: return
	
	match action_id:
		0: # Idle
			nav_agent.target_position = global_position
		1: # Chase
			var player = get_tree().get_first_node_in_group("Player")
			if player:
				nav_agent.target_position = player.global_position
		2: # Attack
			_perform_attack()

func _perform_attack():
	is_locked = true
	anim_tree.set("parameters/conditions/is_attacking", true)
	nav_agent.set_velocity(Vector3.ZERO)
	
	await get_tree().create_timer(0.1).timeout
	anim_tree.set("parameters/conditions/is_attacking", false)
	
	await get_tree().create_timer(1.0).timeout
	is_locked = false

func _move_with_avoidance(safe_velocity):
	pass # Not used in direct movement mode
