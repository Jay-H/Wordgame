extends Control 

# Signal emitted when the timer runs out
signal timeout_reached

@onready var time_label: Label = $Time
@onready var internal_timer: Timer = $InternalTimer

var total_duration_seconds: float = 0.0
var time_remaining_seconds: float = 0.0
var is_timer_running: bool = false

func _ready() -> void:
	# Connect the internal Timer's timeout signal to our handler
	internal_timer.timeout.connect(_on_InternalTimer_timeout)
	
	time_label.add_theme_font_size_override("font_size", Globals.TIMER_LABEL_FONT_SIZE)
	time_label.add_theme_color_override("font_color", Globals.TIMER_LABEL_FONT_COLOR)
	
	# Set initial display (e.g., if loaded from persistence, or before start_timer is called)
	update_timer_display()

func _process(delta: float) -> void:
	# Update the displayed time every frame if the timer is running
	if is_timer_running:
		time_remaining_seconds = internal_timer.time_left # Internal timer keeps track accurately
		update_timer_display()

func start_timer(duration_seconds: float) -> void:
	total_duration_seconds = duration_seconds
	time_remaining_seconds = duration_seconds
	
	internal_timer.wait_time = duration_seconds
	internal_timer.start()
	is_timer_running = true
	update_timer_display()

func stop_timer() -> void:
	internal_timer.stop()
	is_timer_running = false

func reset_timer() -> void:
	stop_timer()
	time_remaining_seconds = total_duration_seconds # Reset to initial duration
	update_timer_display()

func _on_InternalTimer_timeout() -> void:
	is_timer_running = false
	time_remaining_seconds = 0 # make sure it shows 00:00
	update_timer_display()
	emit_signal("timeout_reached")

func update_timer_display() -> void:
	var minutes = floor(time_remaining_seconds / 60)
	var seconds = fmod(time_remaining_seconds, 60)
	time_label.text = "%02d:%02d" % [minutes, seconds]
