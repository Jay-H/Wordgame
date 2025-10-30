extends TextureRect
var paintings = ["res://data/images/pollock_painting.png", "res://data/images/starry_night.jpg"]
signal chosen_colour
var current_painting

@onready var shader_material = material as ShaderMaterial

var light_initial_position
var target_position
var light_position_set = false
var tween_running = false 

func _ready():
	%Reticle.position = material.get_shader_parameter("light_position_pixels") - %Reticle.size/2

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if tween_running == false:
			tween_running = true

			var light_position = material.get_shader_parameter("light_position_pixels")
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_SINE)
			tween.tween_method(light_setter, 0.0, 1.0, 0.5)
			await tween.finished
			tween_running = false
		
func light_setter(time):
	if light_position_set == false:
		light_initial_position = material.get_shader_parameter("light_position_pixels")
		target_position = get_global_mouse_position()
		light_position_set = true
	var current_position = (light_initial_position + (time * (target_position - light_initial_position)))
	material.set_shader_parameter("light_position_pixels",current_position)
	%Reticle.position = current_position - %Reticle.size/2 
	if time >= 1.0:
		var image = texture.get_image()
		var pixel = image.get_pixelv(get_global_mouse_position())
		var reticle_gradient = %Reticle.texture.gradient
		reticle_gradient.set_color(1, pixel)
		%ColourPreview.color = pixel
		light_position_set = false
		target_position = null
		light_initial_position = null

	
	pass


func _on_change_painting_pressed() -> void:
	current_painting = texture
	print(current_painting.resource_path)
	texture = load(paintings[randi_range(0, paintings.size() - 1)])
	
	pass # Replace with function body.
