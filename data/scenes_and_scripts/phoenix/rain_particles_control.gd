extends Control

func _process(_delta):
	$RainParticles.process_material.emission_box_extents.x = self.size.x
	$RainParticles.process_material.emission_box_extents.y = self.size.y
	$RainParticles.position = self.position + self.size/2
