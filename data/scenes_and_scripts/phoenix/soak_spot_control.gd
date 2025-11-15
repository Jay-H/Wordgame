extends Control

@onready var viewport_size = get_viewport_rect().size



func _begin(delay):
	await get_tree().create_timer(delay).timeout
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.start(randf_range(0.1, 3.5))
	timer.timeout.connect(_new_spot.bind(timer))
	
func _new_spot(timer_node):
	timer_node.queue_free()
	var timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.start(randf_range(0.1, 3.5))
	timer.timeout.connect(_new_spot.bind(timer))
	
	var new_position = Vector2(randi_range(0,viewport_size.x), randi_range(0,viewport_size.y))
	var spot_node = load("res://data/scenes_and_scripts/phoenix/soak_spot.tscn").instantiate()
	spot_node.position = new_position
	spot_node.modulate.a = 0
	spot_node.scale = Vector2(0.1,0.1)
	var new_scale_amount = randf_range(0.8,1.5)
	var target_scale = Vector2(new_scale_amount, new_scale_amount)
	self.add_child(spot_node)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(spot_node, "modulate:a", 0.8, 3)
	tween.parallel().tween_property(spot_node, "scale", target_scale, 3)
	tween.chain().tween_property(spot_node, "modulate:a", 0, 2)
	await tween.finished
	spot_node.queue_free()
