#include "../../../Media/built-in-resources/GameFinal.hlsl"

cbuffer cbPerFrame
{
	SDirectionalLight gLight;
	SPointLight gPointLight;
};

struct VertexIn
{
	float3 PosL		: POSITION;
	float3 Normal	: NORMAL;
	float3 Tangent	: TANGENT;
	float2 Tex		: TEXCOORD;

#ifdef INSTANCES_ON
	GF_DECLARE_INTANCES_VERTEX
	float4 Color    : COLOR;
#endif
};

#ifdef INSTANCES_ON 
#define WORLD_TRANSROM (vin.World)
#else
#define WORLD_TRANSROM (GF_WORLD)
#endif

struct VertexOut
{
	float4 PosH		: SV_POSITION;
	float3 PosW		: POSITION;
	float3 Normal	: NORMAL;
#ifdef INSTANCES_ON
	float4 Color    : COLOR;
#endif
};

VertexOut vs_main(VertexIn vin)
{
	VertexOut vout;
	float4 PosW = mul(float4(vin.PosL, 1.0f), WORLD_TRANSROM);
	vout.Normal = mul(vin.Normal, (float3x3)WORLD_TRANSROM);
	vout.PosH = mul(PosW, GF_VIEW_PROJ);
	vout.PosW = PosW.xyz;
#ifdef INSTANCES_ON
	vout.Color = vin.Color;
#endif
	return vout;
}

void shadow_vs_main(VertexIn vin,
	out float4 PosH: SV_POSITION)
{
	float4 PosW = mul(float4(vin.PosL, 1.0f), WORLD_TRANSROM);
	PosH = mul(PosW, GF_VIEW_PROJ);
}

float4 ps_main(VertexOut pin) : SV_TARGET
{
	float3 normal = normalize(pin.Normal);
	float4 diffuse = gLight.Diffuse;
	float4 specular = gLight.Specular;

	PhoneShading(pin.PosW, -gLight.Direction.xyz, normal,
		diffuse, specular, gLight.Specular.w);

#ifdef INSTANCES_ON
	float4 color = pin.Color;
#else
	float4 color = float4(1.0f, 1.0f, 1.0f, 1.0f);
#endif

#ifdef SHADOW_ON
	float shadowFactor = CalcShadowFactor(1, 2.0f);
	
	//float shadowFactor = CalcPointLightShadowFactor(GF_PL_SHADOW_MAP_2, pin.PosW, gPointLight.Position);
	return GF_AMBIENT * GF_MTRL_AMBIENT * color + GF_MTRL_EMISSIVE + 
		diffuse * GF_MTRL_DIFFUSE * shadowFactor * color + 
		specular * GF_MTRL_SPECULAR * shadowFactor;
#else
	return GF_AMBIENT * GF_MTRL_AMBIENT * color + GF_MTRL_EMISSIVE + 
		diffuse * GF_MTRL_DIFFUSE * color + specular * GF_MTRL_SPECULAR;
#endif
}


float4 point_light_ps_main(VertexOut pin) : SV_TARGET
{
	float3 normal = normalize(pin.Normal);
	float4 diffuse;
	float4 specular;

//	bool ComputeIrradianceOfPointLight(float3 pos, SPointLight light, out float3 lightDir,
//	out float4 diffuse, out float4 specular)
	float3 lightDir;
	ComputeIrradianceOfPointLight(pin.PosW, gPointLight, lightDir, diffuse, specular);

	PhoneShading(pin.PosW, lightDir, normal, diffuse, specular, gPointLight.Specular.w);

#ifdef SHADOW_ON
	float shadowFactor = CalcPointLightShadowFactor(2, gPointLight.Position, 10.0f);
	return GF_AMBIENT * GF_MTRL_AMBIENT + GF_MTRL_EMISSIVE + 
		diffuse * GF_MTRL_DIFFUSE * shadowFactor + specular * GF_MTRL_SPECULAR * shadowFactor;
#else
	return GF_AMBIENT * GF_MTRL_AMBIENT + GF_MTRL_EMISSIVE + 
		diffuse * GF_MTRL_DIFFUSE + specular * GF_MTRL_SPECULAR;
#endif
}


struct PointVertexOut
{
	float4 PosH		: SV_POSITION;
	float3 PosW		: POSITION;
};

PointVertexOut point_shadow_vs_main(VertexIn vin)
{
	PointVertexOut vout;
	vout.PosH = mul(float4(vin.PosL, 1.0f), GF_WVP);
	vout.PosW = mul(float4(vin.PosL, 1.0f), GF_WORLD);
	return vout;
}

float4 point_shadow_ps_main(PointVertexOut pin) : SV_TARGET
{
	float3 vLight = pin.PosW - GF_CAMERA_POS;
	float distSqrt = dot(vLight, vLight);

	return float4(distSqrt * 1.2f, 0, 0, 1.0f);
}
