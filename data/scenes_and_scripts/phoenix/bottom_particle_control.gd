extends Control

func _ready():
	$BottomParticles.process_material.emission_box_extents.y = 300

func _process(_delta):
	$BottomParticles.process_material.emission_box_extents.x = self.size.x
	$BottomParticles.process_material.emission_shape_offset.x = self.size.x/2
