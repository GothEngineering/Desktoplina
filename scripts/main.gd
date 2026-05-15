extends Control

@onready var digital_clock: Label = $CenterContainer/Control/DigitalClock
@onready var scplina: Sprite2D = $CenterContainer/Control/Scplina
@onready var states_timer: Timer = $StatesTimer
@onready var slow_walking_timer: Timer = $SlowWalkingTimer
@onready var random_event: Timer = $RandomEvent

var neutralina = preload("res://assets/sprites/desktoplina1.png")
var happylina = preload("res://assets/sprites/desktoplinasaludo.png")

enum State { IDLE, WALKING, PACING, FOLLOWING, SLEEPING, }

# This stopped working LMAO
@export var current_state = State.IDLE

var move_speed = 2
var direction = Vector2(1, 0)
var is_walking = false
var is_following = false
var is_sleeping = false
var follow_speed = 1
var energy_drain = 1.0
var energy_regen = 1.5

var scplina_stats = {
	"energy": 100,
	
}

func _ready() -> void:
	# Forcing the project settings, just in case
	var window = get_window()
	var usable_space = DisplayServer.screen_get_usable_rect()
	var screen_size_taskless = usable_space.end.y - window.size.y
	get_viewport().transparent_bg = true
	window.transparent = true
	window.unresizable = false
	window.borderless = true
	window.always_on_top = true
	window.position = Vector2i(0, screen_size_taskless)

	# The label changes instantly to this
	digital_clock.text = Time.get_time_string_from_system()

	# Things related with timers
	randomize()
	states_timer.start()
	random_event.start(randi_range(60, 1000))
	print("Random event will happen in: ", str(random_event.wait_time))

func _process(delta: float) -> void:
	var window = get_window()

	# The direction the sprite faces when walking
	if direction.x == -1:
		scplina.flip_h = false
	else:
		scplina.flip_h = true

	# If this variable is true; the pet will walk
	if is_walking:
		walking_system()

	if is_following:
		following_system()


	# Energy system
	if !is_sleeping:
		scplina_stats["energy"] -= energy_drain * delta
	else:
		scplina_stats["energy"] += energy_regen * delta

	scplina_stats["energy"] = clamp(scplina_stats["energy"], 0, 100)

	if Input.is_action_just_pressed("Debug Print"):
		print("Current state is: " + str(current_state))

	# Screen boundaries, display server is everything about window management
	# The pet won't go through the sides of the screen, but i think it can still go through the roof
	var usable_space = DisplayServer.screen_get_usable_rect()
	if window.position.x + window.size.x > usable_space.end.x:
		direction.x = -1

	elif window.position.x < usable_space.position.x: #An elif is the middle choice of an if/else
		direction.x = 1

# Movement systems
func walking_system():
	var window = get_window()
	var move_window = Vector2i(direction * move_speed)
	window.position += move_window

func following_system():
	var windowpos = DisplayServer.window_get_position()
	var mousepos = DisplayServer.mouse_get_position()
	if mousepos.x > windowpos.x + 50:
		windowpos.x += follow_speed
		scplina.flip_h = true

	elif mousepos.x < windowpos.x - 50:
		windowpos.x -= follow_speed
		scplina.flip_h = false

	DisplayServer.window_set_position(windowpos)


func changing_state_timer(min_seconds, max_seconds):
	var random_time = randf_range(min_seconds, max_seconds)
	states_timer.start(random_time)

func _on_clock_timer_timeout() -> void: # It would be cool to have another label that shows emotions
	var time = Time.get_time_string_from_system()
	var timer_countdown = states_timer.wait_time
	#digital_clock.text = time # This is the normal clock, i'll use this as a placeholder for anims
	digital_clock.text = str(timer_countdown)
	print(scplina_stats["energy"])

func _on_headpat_pressed() -> void:
	if not is_sleeping:
		scplina.texture = happylina
		print("oli te amo")
		await get_tree().create_timer(0.8).timeout
		scplina.texture = neutralina
		# Find a way to grab her and move her around, draggable

func _on_states_timer_timeout() -> void:
	var random_state = [0, 1, 2, 3].pick_random()
	states_timer.wait_time = randf_range(20.0, 30.0) # Default state in case of bug

	# These are the "default" settings i want to reinforce each timeout
	is_walking = false
	is_following = false
	is_sleeping = false
	scplina.modulate = Color.WHITE
	move_speed = 2
	direction = Vector2(1, 0)
	scplina.rotation_degrees = 0.0

	# Okay just as a reminder or for anyone reading this mess of a code, the pet waits for the current
	# state timer to finish to go to sleep; so basically if the pet gets to 0 energy and it still has 
	# 20 seconds on the state timer, it will wait for those 20 seconds to finish and then go to sleep.
	# I tried forcing the timeout() but it didn't work, so i'll research for a fix later.
	if scplina_stats["energy"] <= 0: 
		current_state = State.SLEEPING
	else:
		if random_state == 0:
			current_state = State.IDLE
		elif random_state == 1:
			current_state = State.WALKING
		elif random_state == 2:
			current_state = State.PACING
		elif random_state == 3:
			current_state = State.FOLLOWING


	match current_state:
		State.IDLE:
			print("oli estoy idle we *no ase nada")
			changing_state_timer(5.0, 10.0)

		State.WALKING:
			print("oli chat estoy caminando uwuuuu")
			is_walking = true
			changing_state_timer(10.0, 20.0)

		State.PACING:
			print("oli toi pacing we")
			changing_state_timer(20.0, 50.0)
			while current_state == State.PACING:
				slow_walking_timer.start(randf_range(2.0, 5.0))
				is_walking = true
				move_speed = [0, 1].pick_random()
				direction.x = [-1, 1].pick_random()
				await slow_walking_timer.timeout

		State.FOLLOWING:
			print("oli estoy siguiendote rawrrrr cosa peruana")
			changing_state_timer(30.0, 60.0)
			while current_state == State.FOLLOWING:
				is_following = true
				following_system()
				slow_walking_timer.start()
				await slow_walking_timer.timeout

		State.SLEEPING:
			print("mimimimimi zzzzzz")
			is_sleeping = true
			scplina.modulate = Color.STEEL_BLUE
			changing_state_timer(50.0, 80.0)
			scplina.rotation_degrees = 90.0

		_:
			print("papu aiuda me bugie")
			states_timer.start()

	states_timer.start()

func _on_random_event_timeout() -> void:
	random_event.start(randi_range(60, 1000))
	# Random events will go here, use an array to get some weird shit like changing the sprite
	# Or making a cute real photo of scp1471 for a second
