extends CharacterBody2D

@export var speed = 200
@export var acceleration = 100 # Added for smoother movement
@export var deceleration = 100 # Added for smoother stopping
@export var air_control = 0.5 # Reduced control in the air
@export var GRAVITY = 980 # Increased gravity for faster falling
@export var jump_force = -300 # Adjusted jump force for better jump height

# Updated animation references to use both sprites
@onready var board_animation = $BoardAnimations
@onready var character_animation = $CharacterAnimations
@onready var camera = $Camera2D

@onready var initial_position = position

# Track animation state
var current_trick = ""
var trick_started = false
var trick_timer = 0.0
var trick_duration = 0.5 # Duration for trick animations in seconds

# Dictionary to store trick-specific durations
var trick_durations = {
	"ollie": 0.5,
	"kickflip": 0.5,
	"heelflip": 0.5,
	"fs_shuvit": 0.5,
	"bs_shuvit": 0.5
}

## Initializes the player character
func _ready():
	# Initialize both animations
	play_both_animations("idle")
	camera.make_current()
	
	# Disable looping for all trick animations at startup
	for sprite in [board_animation, character_animation]:
		sprite.sprite_frames.set_animation_loop("ollie", false)
		sprite.sprite_frames.set_animation_loop("kickflip", false)
		sprite.sprite_frames.set_animation_loop("heelflip", false)
		sprite.sprite_frames.set_animation_loop("fs_shuvit", false)
		sprite.sprite_frames.set_animation_loop("bs_shuvit", false)

## Main physics processing function - called every physics frame
## @param delta: Time elapsed since the previous frame
func _physics_process(delta: float) -> void:
	var on_floor = is_on_floor()
	var in_air = !on_floor
	var idle = on_floor and abs(velocity.x) < 10
	
	# Get input
	var input = {
		"move_left": Input.is_action_pressed("move_left"),
		"move_right": Input.is_action_pressed("move_right"),
		"jump": Input.is_action_pressed("jump"),
		"respawn": Input.is_action_pressed("respawn"),
		"trick_left": Input.is_action_pressed("trick_left"),
		"trick_right": Input.is_action_pressed("trick_right"),
		"trick_up": Input.is_action_pressed("trick_up"),
		"trick_down": Input.is_action_pressed("trick_down"),
		"move_up": Input.is_action_pressed("move_up"),
		"move_down": Input.is_action_pressed("move_down")
	}
	
	# Apply gravity
	apply_gravity(delta, in_air)
	
	# Handle horizontal movement
	handle_movement(delta, on_floor, input)
	
	# Handle respawn
	if input["respawn"]:
		position = initial_position
	
	# Handle jump and tricks
	handle_jump_and_tricks(delta, on_floor, in_air, input)
	
	# Reset trick state when landing
	if on_floor and trick_started:
		trick_started = false
		current_trick = ""
	
	# Idle animation
	if on_floor and idle:
		play_both_animations("idle")
	
	# Move the character
	move_and_slide()

## Applies gravity to the player when in air
## @param delta: Time elapsed since the previous frame
## @param in_air: Boolean indicating if the player is in the air
func apply_gravity(delta: float, in_air: bool) -> void:
	if in_air:
		velocity.y += GRAVITY * delta

## Handles player horizontal movement and related animations
## @param delta: Time elapsed since the previous frame
## @param on_floor: Boolean indicating if the player is on the floor
## @param input: Dictionary containing input state
func handle_movement(delta: float, on_floor: bool, input: Dictionary) -> void:
	var target_speed = 0.0
	
	if input["move_right"]:
		target_speed += float(speed)
		set_facing_direction(false) # Face right
		if on_floor:
			play_both_animations("move")
	elif input["move_left"]:
		target_speed -= float(speed)
		set_facing_direction(true) # Face left
		if on_floor:
			play_both_animations("move")
	
	# Apply acceleration and deceleration
	var accel = float(acceleration) if on_floor else float(acceleration * air_control)
	if target_speed != 0.0:
		velocity.x = lerp(float(velocity.x), target_speed, accel * delta)
	else:
		velocity.x = lerp(float(velocity.x), 0.0, deceleration * delta)

## Handles jump and trick mechanics
## @param delta: Time elapsed since the previous frame
## @param on_floor: Boolean indicating if the player is on the floor
## @param in_air: Boolean indicating if the player is in the air
## @param input: Dictionary containing input state
func handle_jump_and_tricks(delta: float, on_floor: bool, in_air: bool, input: Dictionary) -> void:
	# Jump
	if on_floor and input["jump"]:
		perform_jump()
	
	# Trick animation control
	if in_air:
		trick_timer += delta
		check_and_perform_tricks(input)
		update_trick_animation()

	# Manual tricks
	if input["move_up"]:
		play_both_animations("nose_manual")
	elif input["move_down"]:
		play_both_animations("tail_manual")

## Sets the facing direction for both character and board sprites
## @param face_left: Boolean, true to face left, false to face right
func set_facing_direction(face_left: bool) -> void:
	board_animation.flip_h = face_left
	character_animation.flip_h = face_left

## Plays the same animation on both board and character sprites
## @param anim_name: Name of the animation to play
## @param frame: Optional specific frame to show
## @param should_pause: Whether to pause the animation
func play_both_animations(anim_name: String, frame: int = -1, should_pause: bool = false) -> void:
	board_animation.play(anim_name)
	character_animation.play(anim_name)
	
	if frame >= 0:
		board_animation.frame = frame
		character_animation.frame = frame
		
	if should_pause:
		board_animation.pause()
		character_animation.pause()

## Initiates the player's jump
## Sets the player's vertical velocity to the jump force,
## plays the ollie animation, and initializes trick state
func perform_jump() -> void:
	velocity.y = jump_force
	play_both_animations("ollie")
	current_trick = "ollie"
	trick_started = true
	trick_timer = 0.0

## Checks input and performs tricks based on facing direction
## @param input: Dictionary containing input state
func check_and_perform_tricks(input: Dictionary) -> void:
	# Get input and determine which trick to perform based on facing direction
	var perform_kickflip = false
	var perform_heelflip = false
	var perform_fs_shuvit = false
	var perform_bs_shuvit = false
	
	# If facing right (default sprite direction)
	if !board_animation.flip_h:
		perform_kickflip = input["trick_left"]
		perform_heelflip = input["trick_right"]
		
	# If facing left (flipped sprite)
	else:
		perform_kickflip = input["trick_right"]
		perform_heelflip = input["trick_left"]

	perform_fs_shuvit = input["trick_up"]
	perform_bs_shuvit = input["trick_down"]
	
	# Handle kickflip
	if perform_kickflip and (current_trick == "ollie" or current_trick == ""):
		play_both_animations("kickflip")
		current_trick = "kickflip"
		trick_started = true
		trick_timer = 0.0
		trick_duration = trick_durations["kickflip"]
	
	# Handle heelflip
	if perform_heelflip and (current_trick == "ollie" or current_trick == ""):
		play_both_animations("heelflip")
		current_trick = "heelflip"
		trick_started = true
		trick_timer = 0.0
		trick_duration = trick_durations["heelflip"]

	if perform_fs_shuvit and (current_trick == "ollie" or current_trick == ""):
		play_both_animations("fs_shuvit")
		current_trick = "fs_shuvit"
		trick_started = true
		trick_timer = 0.0
		trick_duration = trick_durations["fs_shuvit"]
	
	if perform_bs_shuvit and (current_trick == "ollie" or current_trick == ""):
		play_both_animations("bs_shuvit")
		current_trick = "bs_shuvit"
		trick_started = true
		trick_timer = 0.0
		trick_duration = trick_durations["bs_shuvit"]

## Updates trick animations based on current trick
func update_trick_animation() -> void:
	# Control animation frames based on current trick
	match current_trick:
		"ollie":
			update_ollie_animation()
		"kickflip":
			update_trick_frame("kickflip")
		"heelflip":
			update_trick_frame("heelflip")
		"fs_shuvit":
			update_trick_frame("fs_shuvit")
		"bs_shuvit":
			update_trick_frame("bs_shuvit")

## Updates the ollie animation based on player's vertical velocity
func update_ollie_animation() -> void:
	# Rising phase (first 30% of jump)
	if velocity.y < 0 and abs(velocity.y) > abs(jump_force * 0.7):
		play_both_animations("ollie", 0)
	# Mid-air phase (middle of jump)
	elif velocity.y < 0 and abs(velocity.y) <= abs(jump_force * 0.7):
		play_both_animations("ollie", 1)
	# Falling phase - force it to stay on frame 2
	else:
		if board_animation.animation != "ollie" or board_animation.frame != 2:
			play_both_animations("ollie", 2, true)

## Updates frames for trick animations based on time
## @param trick_name: The name of the trick animation to update
func update_trick_frame(trick_name: String) -> void:
	# Smoothly transition through trick frames based on time
	var frame_progress = min(trick_timer / trick_duration, 0.99)
	var total_frames = board_animation.sprite_frames.get_frame_count(trick_name)
	var frame = int(frame_progress * total_frames)
	
	board_animation.frame = frame
	character_animation.frame = frame
