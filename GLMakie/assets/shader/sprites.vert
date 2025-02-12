{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};
struct Grid1D{
    int lendiv;
    float start;
    float stop;
    int dims;
};
struct Grid2D{
    ivec2 lendiv;
    vec2 start;
    vec2 stop;
    ivec2 dims;
};
struct Grid3D{
    ivec3 lendiv;
    vec3 start;
    vec3 stop;
    ivec3 dims;
};

{{uv_offset_width_type}} uv_offset_width;
//{{uv_x_type}} uv_width;
{{position_type}} position;
//Assembling functions for creating the right position from the above inputs. They also indicate the type combinations allowed for the above inputs
ivec2 ind2sub(ivec2 dim, int linearindex);
ivec3 ind2sub(ivec3 dim, int linearindex);

{{scale_type}}   scale; // so in the case of distinct x,y,z, there's no chance to unify them under one variable


{{marker_offset_type}} marker_offset;
{{quad_offset_type}} quad_offset;

{{rotation_type}} rotation;

vec4 _rotation(Nothing r){return vec4(0,0,0,1);}
vec4 _rotation(vec2 r){return vec4(r, 0, 1);}
vec4 _rotation(vec3 r){return vec4(r, 1);}
vec4 _rotation(vec4 r){return r;}

float get_rotation_len(Nothing rotation){
    return 1.0;
}

float get_rotation_len(vec4 rotation){
    return 1.0;
}


{{color_type}}        color;
{{color_map_type}}    color_map;
{{intensity_type}}    intensity;
{{color_norm_type}}   color_norm;

float get_intensity(vec4 rotation, Nothing position_z, int index){return length(rotation);}
float get_intensity(vec3 rotation, Nothing position_z, int index){return length(rotation);}
float get_intensity(vec2 rotation, Nothing position_z, int index){return length(rotation);}
float get_intensity(Nothing rotation, float position_z, int index){return position_z;}
float get_intensity(vec3 rotation, float position_z, int index){return position_z;}
vec4 color_lookup(float intensity, sampler1D color_ramp, vec2 norm);

vec4 _color(vec3 color, Nothing intensity, Nothing color_map, Nothing color_norm, int index, int len);
vec4 _color(vec4 color, Nothing intensity, Nothing color_map, Nothing color_norm, int index, int len);
vec4 _color(Nothing color, float intensity, sampler1D color_map, vec2 color_norm, int index, int len);
vec4 _color(Nothing color, sampler1D intensity, sampler1D color_map, vec2 color_norm, int index, int len);

{{stroke_color_type}} stroke_color;
{{glow_color_type}} glow_color;

uniform bool scale_primitive;
uniform mat4 preprojection;
uniform mat4 model;
uniform uint objectid;
uniform int len;

out uvec2 g_id;
out int   g_primitive_index;
out vec3  g_position;
out vec4  g_offset_width;
out vec4  g_uv_texture_bbox;
out vec4  g_rotation;
out vec4  g_color;
out vec4  g_stroke_color;
out vec4  g_glow_color;
out float g_clip_distance[8];

vec4 to_vec4(vec3 x){return vec4(x, 1.0);}
vec4 to_vec4(vec4 x){return x;}

uniform int num_clip_planes;
uniform vec4 clip_planes[8];

void process_clip_planes_alt(vec3 world_pos)
{
    // distance = dot(world_pos - plane.point, plane.normal)
    // precalculated: dot(plane.point, plane.normal) -> plane.w
    for (int i = 0; i < num_clip_planes; i++)
        g_clip_distance[i] = dot(world_pos, clip_planes[i].xyz) - clip_planes[i].w;

    // TODO: can be skipped?
    for (int i = num_clip_planes; i < 8; i++)
        g_clip_distance[i] = 1.0;
}

void main(){
    int index         = gl_VertexID;
    g_primitive_index = index;
    vec3 pos;
    {{position_calc}}
    vec4 world_pos = model * vec4(pos, 1);
    process_clip_planes_alt(world_pos.xyz);
    vec4 p = preprojection * world_pos;
    if (scale_primitive)
        g_position = p.xyz / p.w + mat3(model) * marker_offset;
    else
        g_position = p.xyz / p.w + marker_offset;
    g_offset_width.xy = quad_offset.xy;
    g_offset_width.zw = scale.xy;
    g_color           = _color(color, intensity, color_map, color_norm, g_primitive_index, len);
    g_rotation        = _rotation(rotation);
    g_uv_texture_bbox = uv_offset_width;
    g_stroke_color    = to_vec4(stroke_color);
    g_glow_color      = to_vec4(glow_color);

    g_id              = uvec2(objectid, index+1);
}
