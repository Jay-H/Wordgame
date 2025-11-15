@tool
extends EditorPlugin


const OVERRIDE_NAMES: Dictionary = { #Dictionary[String, Array[String]]
	'icon': ['icon'],
	'stylebox': [
		'normal', 'focus', 'disabled', 'pressed', 'hover', 'hover_pressed', 'read_only',
		'normal_mirrored', 'focus_mirrored', 'disabled_mirrored', 'pressed_mirrored', 'hover_mirrored', 'hover_pressed_mirrored',
		'cursor', 'cursor_unfocused', 'selected', 'selected_focus', 'hovered'
	],
	'font_size': [
		'font_size', 'bold_font_size', 'bold_italics_font_size', 
		'italics_font_size', 'mono_font_size', 'normal_font_size',
	],
	'font': ['font'],
	'constant': [
		'outline_size', 'icon_max_width', 'icon_separation', 'line_separation',
		'v_separation', 'h_separation', 'icon_margin',
		'shadow_offset_x', 'shadow_offset_y', 'icon_margin',
	],
	'color': [
		'font_color',  'font_disabled_color',  'font_focus_color',  'font_hover_color',
		'font_hover_pressed_color',  'font_outline_color',  'font_pressed_color',
		
		'font_shadow_color',  'icon_focus_color',  'icon_hover_color',
		'icon_disabled_color',  'icon_focus_color',  'icon_hover_color',
		'icon_hover_pressed_color',  'icon_normal_color',  'icon_pressed_color'
	]
}
const CLASS_OVERRIDES: Dictionary = { #Dictionary[String, Dictionary[String, Array[String]]]
	&'LineEdit': {
		'color': [
			'caret_color',  'clear_button_color',  'clear_button_color_pressed',
			'font_placeholder_color',  'font_selected_color',
			'font_uneditable_color',  'selection_color',
		],
		'constant': ['minimum_character_width'],
	},
	&'BoxContainer': {
		'color': [
			'caret_color',  'clear_button_color',  'clear_button_color_pressed',
			'font_placeholder_color',  'font_selected_color',
			'font_uneditable_color',  'selection_color',
		],
		'constant': ['separation'],
	},
	&'CheckBox': {
		'color': [
			'checked',  'checked_disabled',  'unchecked', 'unchecked_disabled',
			'radio_checked',  'radio_checked_disabled',  'radio_unchecked', 'radio_unchecked_disabled',
		],
		'constant': ['check_v_offset']
	},
	&'MarginContainer': {
		'constant': ['margin_left',  'margin_right',  'margin_top', 'margin_bottom'],
	},
	&'Panel': {
		'stylebox': ['panel']
	},
	&'PanelContainer': {
		'stylebox': ['panel']
	},
	&'GraphNode': {
		'color': [
			'resizer_color',
		]
	},
	&'LinkButton': {
		'constant': ['underline_spacing'],
	},
	&'PopupMenu': {
		'constant': ['underline_spacing'],
		'color': ['font_separator_color', 'font_separator_outline_color', 'font_accelerator_color']
	},
	&'RichTextLabel': {
		'font': ['bold_font', 'bold_italics_font', 'italics_font', 'mono_font', 'normal_font']
	},
	
	&'ColorPicker': {
		'constant': [
			'center_slider_grabbers', 'h_width', 'label_width', 'margin', 'sv_height', 'sv_width',
		],
		'icon': [
			'add_preset', 'bar_arrow', 'color_hue', 'color_okhsl_hue',
			'expanded_arrow', 'folded_arrow', 'overbright_indicator', 'picker_cursor',
			'sample_bg', 'screen_picker', 'shape_circle', 'shape_rect', 'shape_rect_wheel',
		],
	},
	&'CodeEdit': {
		'constant': ['completion_lines', 'completion_max_width', 'completion_scroll_width'],
		'color': [
			'bookmark_color', 'brace_mismatch_color', 'breakpoint_color', 'code_folding_color',
			'completion_background_color', 'completion_existing_color', 'completion_scroll_color',
			'completion_scroll_hovered_color', 'completion_selected_color', 'executing_line_color',
			'folded_code_region_color', 'line_length_guideline_color', 'line_number_color',
		],
		'icon': [
			'bookmark',
			'breakpoint',
			'can_fold',
			'can_fold_code_region',
			'executing_line',
			'folded',
			'folded_code_region',
			'folded_eol_icon',
		],
		'stylebox': ['completion']
	},
	&'TabContainer': {
		'constant': ['side_margin'],
		'size': ['font_size'],
		'color': [
			'drop_mark_color', 'font_disabled_color', 'font_hovered_color', 'font_outline_color',
			'font_selected_color', 'font_unselected_color',
		],
		'icon': [
			'decrement', 'decrement_highlight', 'drop_mark', 'increment',
			'increment_highlight', 'menu', 'menu_highlight',
		],
		'stylebox': [
			'panel', 'tab_disabled', 'tab_focus', 'tab_hovered', 'tab_selected',
			'tab_unselected', 'tabbar_background'
		]
	},
	
	
	
	
	
	&'Window': {
		'color': [
			'title_color',  'title_color_modulate',
		],
		'constant': [
			'close_h_offset', 'close_v_offset', 'resize_margin', 'title_height', 'title_outline_size'
		],
	},
	&'Tree': {
		'font': ['title_button_font'],
		'font_size': ['title_button_font_size'],
		'color': [
			'children_hl_line_color', 'custom_button_font_highlight', 'drop_position_color', 'font_color',
			'font_outline_color', 'font_selected_color', 'guide_color', 'parent_hl_line_color',
			'relationship_line_color', 'title_button_color',
		],
		'constant': [
			'button_margin', 'children_hl_line_width', 'draw_guides', 'draw_relationship_lines',
			'h_separation', 'icon_max_width', 'inner_item_margin_bottom', 'inner_item_margin_left',
			'inner_item_margin_right', 'inner_item_margin_top', 'item_margin', 'outline_size',
			'parent_hl_line_margin', 'parent_hl_line_width', 'relationship_line_width', 'scroll_border',
			'scroll_speed', 'scrollbar_h_separation', 'scrollbar_margin_bottom', 'scrollbar_margin_left',
			'scrollbar_margin_right', 'scrollbar_margin_top', 'scrollbar_v_separation', 'v_separation',
		],
		'icon': [
			'arrow', 'arrow_collapsed', 'arrow_collapsed_mirrored', 'checked',
			'indeterminate', 'select_arrow', 'unchecked', 'updown',
		],
		'stylebox': [
			'button_pressed', 'cursor', 'cursor_unfocused', 'custom_buttonDefault', 'custom_button_hover',
			'custom_button_pressed', 'focus', 'panel', 'selected', 'selected_focus',
 			'title_button_hover', 'title_button_normalDefault', 'title_button_pressed',
		],
	},
	&'FileDialog': {
		'color': [
			'file_disabled_color', 'file_icon_color', 'folder_icon_color',
		],
		'icon': [
			'back_folder', 'file', 'folder', 'forward_folder',
			'parent_folder', 'reload', 'toggle_hidden',
		]
	},
}



var buttons: HBoxContainer


func _enter_tree():
	if buttons != null:
		buttons.queue_free()
		buttons = null
	
	buttons = preload('buttons.tscn').instantiate()
	(buttons.get_node('remove_overrides_button') as Button).pressed.connect(func() -> void:
		var selection := get_editor_interface().get_selection()
		var changes_dict: Dictionary = {} #Dictionary[Node, Dictionary[String, Dictionary[String, Array[Variant]]]]
		
		for v: Node in selection.get_selected_nodes(): ##Array[Node]
			if (v is Control) or (v is Window):
				var object_class_name: String = v.get_class()
				
				if v.theme != null:
					_add_override_change(
						v,
						'_theme',
						'_theme',
						v.theme,
						null,
						changes_dict
					)
				
				for style_name: String in OVERRIDE_NAMES:
					var overrides_dict: Array  = OVERRIDE_NAMES[style_name] #Array[String]
					if CLASS_OVERRIDES.has(object_class_name) and CLASS_OVERRIDES[object_class_name].has(style_name):
						overrides_dict += CLASS_OVERRIDES[object_class_name][style_name] ##Array[String]
					
					
					for override_name: String in overrides_dict: ##Array[String]
						if v['has_theme_' + style_name + '_override'].call(StringName(override_name)):
							var undo_value: Variant = v['get_theme_' + style_name].call(StringName(override_name))
							v['remove_theme_' + style_name + '_override'].call(StringName(override_name))
							#I dont know why StringName. Just fewer warnings
							
							var new_value: Variant =  v['get_theme_' + style_name].call(StringName(override_name))
							_add_override_change(
								v,
								style_name,
								override_name,
								undo_value,
								null if (new_value is Object) else new_value,
								changes_dict
							)
		
		
		if changes_dict.is_empty():
			print('No overrides detected')
			return
		
		
		var properties_changed_count := 0
		var nodes_count := 0
		for object: Node in changes_dict:
			if (object == null):		continue
			nodes_count += 1
			for style_name: String in changes_dict[object]:
				if style_name == '_theme':		continue
				for override_name: String in changes_dict[object][style_name]:
					properties_changed_count += 1
		
		var editor_undoredo := get_undo_redo()
		editor_undoredo.create_action('Remove theme overrides for ' + str(nodes_count) + ' nodes (' + str(properties_changed_count) + ' properties summary)')
		editor_undoredo.add_do_method(self, &'_back_overrride_value', changes_dict, false) #is_undo = false
		editor_undoredo.add_undo_method(self, &'_back_overrride_value', changes_dict, true) ##is_undo = true
		
		editor_undoredo.commit_action(true)
		
		if 1:
			buttons.self_modulate = Color.GREEN
			await get_tree().create_timer(0.1).timeout
			buttons.self_modulate = Color.WHITE
	)
	(buttons.get_node('convert_to_theme_button') as Button).pressed.connect(func() -> void:
		var selection := get_editor_interface().get_selection()
		var theme_dict: Dictionary = {} #Dictionary[String, Dictionary[String, Dictionary[String, Array[Variant]]]]
		
		for v: Node in selection.get_selected_nodes(): ##Array[Node]
			if (v is Control) or (v is Window):
				var object_class_name: String = v.get_class()
				
				for style_name: String in OVERRIDE_NAMES:
					var overrides_dict: Array  = OVERRIDE_NAMES[style_name] #Array[String]
					if CLASS_OVERRIDES.has(object_class_name) and CLASS_OVERRIDES[object_class_name].has(style_name):
						overrides_dict += CLASS_OVERRIDES[object_class_name][style_name] ##Array[String]
					
					for override_name: String in overrides_dict: ##Array[String]
						if v['has_theme_' + style_name + '_override'].call(StringName(override_name)):
							if !theme_dict.has(object_class_name):
								theme_dict[object_class_name] = {}
							if !theme_dict[object_class_name].has(style_name):
								theme_dict[object_class_name][style_name] = {}
							
							theme_dict[object_class_name][style_name][override_name] = v['get_theme_' + style_name].call(StringName(override_name))
		
		
		if theme_dict.is_empty():
			print('No overrides detected')
			return
		
		
		var new_theme := Theme.new()
		
		var properties_changed_count := 0
		for object_class_name: String in theme_dict:
			for style_name: String in theme_dict[object_class_name]:
				for override_name: String in theme_dict[object_class_name][style_name]:
					new_theme['set_' + style_name].call(override_name, object_class_name, theme_dict[object_class_name][style_name][override_name])
					properties_changed_count += 1
		
		
		var filters := PackedStringArray()
		filters.append('*.tres')
		DisplayServer.file_dialog_show('Save theme (' + str(properties_changed_count) + ' properties)', 'res://', 'overrrides_theme.tres', false, DisplayServer.FILE_DIALOG_MODE_SAVE_FILE, filters,
			func(status: bool, selected_paths: PackedStringArray, _selected_filter_index: int) -> void:
				if status:
					if new_theme != null:
						var path := selected_paths[0]
						var file_name = path.get_slice('\\', path.get_slice_count('\\') - 1)
						var file_parent_path = path.trim_suffix(file_name)
						file_name = file_name.trim_suffix(file_name.get_slice('.', file_name.get_slice_count('.') - 1)).replace('.', '')
						#no extension
						
						prints(file_parent_path, '   ', file_name)
						
						var save_error := ResourceSaver.save(new_theme, file_parent_path + '\\' + file_name + '.tres')
						new_theme = null
						if save_error:
							printerr('Theme save error: ' + error_string(save_error))
		)
	)
	
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, buttons)




static func _back_overrride_value(changes_dict: Dictionary, is_undo: bool) -> void:
	for object: Node in changes_dict:
		if !object:		continue
		
		for style_name: String in changes_dict[object]:
			if style_name == '_theme':		continue
			for override_name: String in changes_dict[object][style_name]:
				var value: Variant = changes_dict[object][style_name][override_name][0 if is_undo else 1]
				if value != null:
					#line 63
					if !(('fallback_' + style_name) in ThemeDB) or ((('fallback_' + style_name) in ThemeDB) and ThemeDB['fallback_' + style_name] != value):
						object['add_theme_' + style_name + '_override'].call(StringName(override_name), value)
						continue
				
				object['remove_theme_' + style_name + '_override'].call(StringName(override_name))



static func _add_override_change(object: Node, style_name: String, override_name: String, undo_value: Variant, new_value: Variant, changes_dict: Dictionary) -> void:
	if (undo_value == new_value):
		return
	
	if !changes_dict.has(object):
		changes_dict[object] = {}
	
	if !changes_dict[object].has(style_name):
		changes_dict[object][style_name] = {}
	
	
	#FOR UNDO, REDO ACTIONS
	changes_dict[object][style_name][override_name] = []
	changes_dict[object][style_name][override_name].append(undo_value) ##[0]; old value
	changes_dict[object][style_name][override_name].append(new_value) ##[1]; new value




func _exit_tree():
	if buttons != null:
		remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, buttons)
		buttons.queue_free()
		buttons = null
