@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeSpecularSchlickGGX

# CC0 1.0 Universal, ElSuicio, 2025.
# GODOT v4.4.1.stable.
# x.com/ElSuicio
# github.com/ElSuicio
# Contact email [interdreamsoft@gmail.com]

func _get_name() -> String:
	return "SchlickGGX"

func _get_category() -> String:
	return "Lightning/Specular"

func _get_description() -> String:
	return "Schlick-GGX Specular Reflectance Model."

func _get_return_icon_type() -> PortType:
	return VisualShaderNode.PORT_TYPE_VECTOR_3D

func _is_available(mode : Shader.Mode, type : VisualShader.Type) -> bool:
	if( mode == Shader.MODE_SPATIAL and type == VisualShader.TYPE_LIGHT ):
		return true
	else:
		return false

#region Input
func _get_input_port_count() -> int:
	return 9

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
			return "Diffuse Color"
		6:
			return "Roughness"
		7:
			return "Metallic"
		8:
			return "Metallic Specular"
	
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
			return PORT_TYPE_VECTOR_3D # Diffuse Color.
		6:
			return PORT_TYPE_SCALAR # Roughness.
		7:
			return PORT_TYPE_SCALAR # Metallic.
		8:
			return PORT_TYPE_SCALAR # Metallic Specular.
	
	return PORT_TYPE_SCALAR

#endregion

#region Output
func _get_output_port_count() -> int:
	return 1

func _get_output_port_name(_port : int) -> String:
	return "Specular"

func _get_output_port_type(_port : int) -> PortType:
	return PORT_TYPE_VECTOR_3D

func _get_input_port_default_value(port : int) -> Variant:
	match port:
		8:
			return 0.5
	
	return

#endregion

func _get_code(input_vars : Array[String], output_vars : Array[String], _mode : Shader.Mode, _type : VisualShader.Type) -> String:
	var default_vars : Array[String] = [
		"NORMAL",
		"LIGHT",
		"VIEW",
		"LIGHT_COLOR",
		"ATTENUATION",
		"ALBEDO",
		"ROUGHNESS",
		"METALLIC"
		]
	
	for i in range(0, input_vars.size(), 1):
		if(!input_vars[i]):
			input_vars[i] = default_vars[i]
	
	var shader : String = """
	vec3 n = normalize( {normal} );
	vec3 l = normalize( {light} );
	vec3 v = normalize( {view} );
	
	float NdotL = min(max(dot(n, l), 1e-3), 1.0); // cos(theta_l) == cos(theta_i).
	float NdotV = min(max(dot(n, v), 1e-3), 1.0); // cos(theta_v) == cos(theta_r).
	
	vec3 h = normalize(v + l); // Halfway Vector.
	
	float HdotN = dot(h, n); // cos(theta_h).
	float HdotL = dot(h, l); // cos(theta_d).
	
	float alpha = {roughness} * {roughness}; // Variance.
	float alpha2 = alpha * alpha;
	
	/* Normal Distribution Function (Trowbridge-Reitz-GGX) */
	float t = 1.0 + (alpha2 - 1.0) * HdotN * HdotN;
	float D = alpha2 / (PI * t * t);
	
	/* Geometric Function (Implicit) */
	float G = 0.5 / mix(2.0 * NdotL * NdotV, NdotL + NdotV, alpha);
	
	/* Fresnel Function (Schlick’s Approximation) */
	float dielectric = 0.16 * {metallic_specular} * {metallic_specular};
	
	vec3 f0 = mix(vec3( dielectric ), {diffuse_color}, vec3( {metallic} )); 
	float f90 = clamp(dot(f0, vec3(16.5)), {metallic}, 1.0);
	
	vec3 F = f0 + (f90 - f0) * pow(1.0 - HdotL, 5.0);
	
	vec3 specular_schlick_ggx = D * G * F * NdotL;
	
	{output} = {light_color} * {attenuation} * specular_schlick_ggx;
	"""
	
	return shader.format({
		"normal" : input_vars[0],
		"light" : input_vars[1],
		"view" : input_vars[2],
		"light_color" : input_vars[3],
		"attenuation" : input_vars[4],
		"diffuse_color" : input_vars[5],
		"roughness" : input_vars[6],
		"metallic" : input_vars[7],
		"metallic_specular" : input_vars[8],
		"output" : output_vars[0]
		})
