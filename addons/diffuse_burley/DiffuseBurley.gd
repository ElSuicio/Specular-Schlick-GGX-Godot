@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeDiffuseBurley

# CC0 1.0 Universal, ElSuicio, 2025.
# GODOT v4.4.1.stable.
# x.com/ElSuicio
# github.com/ElSuicio
# Contact email [interdreamsoft@gmail.com]

func _get_name() -> String:
	return "Burley"

func _get_category() -> String:
	return "Lightning/Diffuse"

func _get_description() -> String:
	return "Disney Principled PBS diffuse light model."

func _get_return_icon_type() -> PortType:
	return VisualShaderNode.PORT_TYPE_VECTOR_3D

func _is_available(mode : Shader.Mode, type : VisualShader.Type) -> bool:
	if( mode == Shader.MODE_SPATIAL and type == VisualShader.TYPE_LIGHT ):
		return true
	else:
		return false

#region Input
func _get_input_port_count() -> int:
	return 6

func _get_input_port_name(port : int) -> String:
	match port:
		0:
			return "Normal"
		1:
			return "Light"
		2:
			return "View"
		3:
			return "Light Color"
		4:
			return "Attenuation"
		5:
			return "Roughness"
	
	return ""

func _get_input_port_type(port : int) -> PortType:
	match port:
		0:
			return PORT_TYPE_VECTOR_3D # Normal.
		1:
			return PORT_TYPE_VECTOR_3D # Light.
		2:
			return PORT_TYPE_VECTOR_3D # View.
		3:
			return PORT_TYPE_VECTOR_3D # Light Color.
		4:
			return PORT_TYPE_SCALAR # Attenuation.
		5:
			return PORT_TYPE_SCALAR # Roughness.
	
	return PORT_TYPE_SCALAR

#endregion


#region Output
func _get_output_port_count() -> int:
	return 1

func _get_output_port_name(_port : int) -> String:
	return "Diffuse"

func _get_output_port_type(_port : int) -> PortType:
	return PORT_TYPE_VECTOR_3D

#endregion

func _get_code(input_vars : Array[String], output_vars : Array[String], _mode : Shader.Mode, _type : VisualShader.Type) -> String:
	var default_vars : Array[String] = [
		"NORMAL",
		"LIGHT",
		"VIEW",
		"LIGHT_COLOR",
		"ATTENUATION",
		"ROUGHNESS"
		]
	
	for i in range(0, input_vars.size(), 1):
		if(!input_vars[i]):
			input_vars[i] = default_vars[i]
	
	var shader : String = """
	const float INV_PI = 0.31830988618379067154;
	
	vec3 n = normalize( {normal} );
	vec3 l = normalize( {light} );
	vec3 v = normalize( {view} );
	
	float NdotL = min(max(dot(n, l), 1e-3), 1.0); // cos(theta_l) == cos(theta_i).
	float NdotV = min(max(dot(n, v), 1e-3), 1.0); // cos(theta_v) == cos(theta_r).
	
	vec3 h = normalize(v + l);
	
	float HdotL = dot(h, v); // cos(theta_d).
	
	// https://media.disneyanimation.com/uploads/production/publication_asset/48/asset/s2012_pbs_disney_brdf_notes_v3.pdf
	
	float FD90 = 0.5 + 2.0 * {roughness} * HdotL * HdotL;
	
	float FD_l = pow(clamp(1.0 - NdotL, 0.0, 1.0), 5.0);
	float FD_v = pow(clamp(1.0 - NdotV, 0.0, 1.0), 5.0);
	
	float diffuse_burley = INV_PI * mix(1.0, FD90, FD_l) * mix(1.0, FD90, FD_v) * NdotL;
	
	{output} = {light_color} * {attenuation} * diffuse_burley;
	"""
	
	return shader.format({
		"normal" : input_vars[0],
		"light" : input_vars[1],
		"view" : input_vars[2],
		"light_color" : input_vars[3],
		"attenuation" : input_vars[4],
		"roughness" : input_vars[5],
		"output" : output_vars[0]
		})
