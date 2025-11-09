extends Control

func _ready():
	$GPUParticles2D.process_material.emission_box_extents.y = 300

func _process(_delta):
	$GPUParticles2D.process_material.emission_box_extents.x = self.size.x
	$GPUParticles2D.process_material.emission_shape_offset.x = self.size.x/2
