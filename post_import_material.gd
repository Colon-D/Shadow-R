@tool # Needed so it runs in editor.
extends EditorScenePostImport

# This sample changes all node names.
# Called right after the scene is imported and gets the root node.
func _post_import(scene):
	# Change all node names to "modified_[oldnodename]"
	iterate(scene)
	return scene # Remember to return the imported scene

# Recursive function that is called on every node
# (for demonstration purposes; EditorScenePostImport only requires a `_post_import(scene)` function).
func iterate(node):
	if node != null:
		if node is MeshInstance3D:
			var mesh_instance = node as MeshInstance3D
			var mesh = mesh_instance.mesh as ArrayMesh
			var surfaces = mesh.get_surface_count()
			for s in range(surfaces):
				var surface_mat = mesh.surface_get_material(s) as StandardMaterial3D
				if surface_mat == null:
					continue
				var new_material = ShaderMaterial.new()
				var albedo_texture = surface_mat.albedo_texture
				new_material.shader = preload("res://models/retro.gdshader")
				new_material.set_shader_parameter("texture_albedo", surface_mat.albedo_texture)
				mesh.surface_set_material(s, new_material)
		# 2025-12-31 addition, because Godot 4.5 (then 4.4.1) disabled backface_collision
		elif node is CollisionShape3D:
			var shape_instance = node as CollisionShape3D
			if shape_instance.shape is ConcavePolygonShape3D:
				var shape = shape_instance.shape as ConcavePolygonShape3D
				shape.backface_collision = true

		for child in node.get_children():
			iterate(child)
