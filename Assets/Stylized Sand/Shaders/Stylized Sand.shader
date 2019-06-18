// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Stylized/Sand"
{
	Properties
	{
		[Header(General Settings)]_Lit("Lit", Color) = (0.9333333,0.8,0.7450981,0)
		_Shadow("Shadow", Color) = (0.8862745,0.572549,0.4039216,0)
		[Toggle]_SubtractiveShadows("Subtractive Shadows", Float) = 0
		_ModifiedLambertStength("Modified Lambert Stength", Range( 0 , 1)) = 0
		[NoScaleOffset][Normal][Header(Sand Normals)]_SandNormal("Sand Normal", 2D) = "bump" {}
		_SandNormalScale("Sand Normal Scale", Float) = 1
		_SandNormalRotation("Sand Normal Rotation", Range( 0 , 1)) = 0
		_SandNormalStrength("Sand Normal Strength", Range( 0 , 1)) = 0
		[Toggle(_MODULATESTRENGTHBYDISTANCE_ON)] _ModulateStrengthByDistance("Modulate Strength By Distance", Float) = 0
		_DistanceOffset("Distance Offset", Float) = 200
		_DistanceStrength("Distance Strength", Float) = 75
		[NoScaleOffset][Normal][Header(Glitter)]_GlitterNormal("Glitter Normal", 2D) = "bump" {}
		_GlitterNormalScale("Glitter Normal Scale", Float) = 1
		_GlitterSpecularExponent("Glitter Specular Exponent", Float) = 0
		_CameraContribution("Camera Contribution", Range( 0 , 1)) = 0.001
		[Toggle]_GlitterinShadows("Glitter in Shadows", Float) = 0
		[Header(Sun Specular)]_SunSpecularExponent("Sun Specular Exponent", Float) = 0
		_SunSpecularGraininess("Sun Specular Graininess", Range( 0 , 1)) = 0
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#pragma shader_feature _MODULATESTRENGTHBYDISTANCE_ON
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
			float3 worldRefl;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform half4 _Shadow;
		uniform half4 _Lit;
		uniform half _SubtractiveShadows;
		uniform sampler2D _SandNormal;
		uniform half _SandNormalScale;
		uniform half _SandNormalRotation;
		uniform half _SandNormalStrength;
		uniform half _DistanceOffset;
		uniform half _DistanceStrength;
		uniform half _ModifiedLambertStength;
		uniform half _GlitterinShadows;
		uniform half _SunSpecularGraininess;
		uniform half _SunSpecularExponent;
		uniform sampler2D _GlitterNormal;
		uniform half _GlitterNormalScale;
		uniform half _CameraContribution;
		uniform half _GlitterSpecularExponent;

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			#ifdef UNITY_PASS_FORWARDBASE
			float ase_lightAtten = data.atten;
			if( _LightColor0.a == 0)
			ase_lightAtten = 0;
			#else
			float3 ase_lightAttenRGB = gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 );
			float ase_lightAtten = max( max( ase_lightAttenRGB.r, ase_lightAttenRGB.g ), ase_lightAttenRGB.b );
			#endif
			#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
			half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
			float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
			float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
			ase_lightAtten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
			#endif
			float3 ase_worldPos = i.worldPos;
			float2 appendResult3_g9 = (half2(ase_worldPos.x , ase_worldPos.z));
			float cos4_g8 = cos( ( _SandNormalRotation * 6.28318548202515 ) );
			float sin4_g8 = sin( ( _SandNormalRotation * 6.28318548202515 ) );
			float2 rotator4_g8 = mul( ( appendResult3_g9 / _SandNormalScale ) - float2( 0.5,0.5 ) , float2x2( cos4_g8 , -sin4_g8 , sin4_g8 , cos4_g8 )) + float2( 0.5,0.5 );
			#ifdef _MODULATESTRENGTHBYDISTANCE_ON
				float staticSwitch304 = saturate( ( ( ( 1.0 - distance( ase_worldPos , _WorldSpaceCameraPos ) ) + _DistanceOffset ) / _DistanceStrength ) );
			#else
				float staticSwitch304 = (float)1;
			#endif
			float3 lerpResult249 = lerp( float3( 0,0,1 ) , UnpackNormal( tex2D( _SandNormal, rotator4_g8 ) ) , ( _SandNormalStrength * staticSwitch304 ));
			float lerpResult316 = lerp( 1.0 , 0.3 , _ModifiedLambertStength);
			float3 appendResult317 = (half3(1.0 , lerpResult316 , 1.0));
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult318 = dot( (WorldNormalVector( i , ( lerpResult249 * appendResult317 ) )) , ase_worldlightDir );
			float lerpResult322 = lerp( 1.0 , 4.0 , _ModifiedLambertStength);
			float temp_output_339_0 = saturate( ase_lightAtten );
			float4 lerpResult67 = lerp( _Shadow , _Lit , lerp(( saturate( ( dotResult318 * lerpResult322 ) ) * temp_output_339_0 ),( saturate( ( dotResult318 * lerpResult322 ) ) - ( 1.0 - temp_output_339_0 ) ),_SubtractiveShadows));
			float3 lerpResult354 = lerp( float3( 0,0,1 ) , lerpResult249 , _SunSpecularGraininess);
			float dotResult206 = dot( WorldReflectionVector( i , lerpResult354 ) , ase_worldlightDir );
			float2 appendResult3_g12 = (half2(ase_worldPos.x , ase_worldPos.z));
			half3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float dotResult217 = dot( WorldReflectionVector( i , UnpackNormal( tex2D( _GlitterNormal, ( ( appendResult3_g12 / _GlitterNormalScale ) - ( (_WorldSpaceCameraPos).xz * _CameraContribution ) ) ) ) ) , ase_worldViewDir );
			float temp_output_335_0 = ( saturate( pow( ( ( dotResult206 + 1.0 ) * 0.5 ) , _SunSpecularExponent ) ) + saturate( pow( ( ( dotResult217 + 1.0 ) * 0.5 ) , _GlitterSpecularExponent ) ) );
			c.rgb = ( lerpResult67 + lerp(( temp_output_339_0 * temp_output_335_0 ),temp_output_335_0,_GlitterinShadows) ).rgb;
			c.a = 1;
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows noambient nolightmap  nodynlightmap nodirlightmap nometa noforwardadd 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float4 tSpace0 : TEXCOORD1;
				float4 tSpace1 : TEXCOORD2;
				float4 tSpace2 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.worldRefl = -worldViewDir;
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputCustomLightingCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputCustomLightingCustom, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=16700
243;73;1289;653;1338.176;402.6176;1.087494;True;False
Node;AmplifyShaderEditor.CommentaryNode;308;-4806.223,-983.4685;Float;False;2154.5;578.1957;;18;249;102;297;307;250;304;106;254;298;305;303;300;296;302;299;292;293;294;Sand Normals;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;293;-4756.223,-577.9094;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;294;-4677.375,-724.012;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DistanceOpNode;292;-4464.177,-657.7542;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;299;-4351.609,-568.4137;Float;False;Property;_DistanceOffset;Distance Offset;9;0;Create;True;0;0;False;0;200;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;302;-4313.644,-657.7203;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;300;-4130.25,-624.4374;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;296;-4215.332,-495.0453;Float;False;Property;_DistanceStrength;Distance Strength;10;0;Create;True;0;0;False;0;75;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;303;-3992.419,-574.2741;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;334;-3262.145,193.2474;Float;False;2213.452;454.26;;15;231;238;230;233;226;331;232;223;218;278;217;219;221;220;222;Glitter Specular;1,1,1,1;0;0
Node;AmplifyShaderEditor.IntNode;305;-3862.94,-654.1448;Float;False;Constant;_Int0;Int 0;20;0;Create;True;0;0;False;0;1;0;0;1;INT;0
Node;AmplifyShaderEditor.SaturateNode;298;-3858.323,-573.3755;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;231;-3212.145,343.1414;Float;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;254;-4048.648,-856.2178;Float;False;Property;_SandNormalRotation;Sand Normal Rotation;6;0;Create;True;0;0;False;0;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;106;-3994.781,-933.4686;Float;False;Property;_SandNormalScale;Sand Normal Scale;5;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;325;-2354.852,-920.5715;Float;False;1793.557;410.7913;;10;324;320;322;318;323;319;315;317;316;66;Diffuse Term;1,1,1,1;0;0
Node;AmplifyShaderEditor.SwizzleNode;233;-2847.147,337.9573;Float;False;FLOAT2;0;2;2;2;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;250;-3604.439,-719.6232;Float;False;Property;_SandNormalStrength;Sand Normal Strength;7;0;Create;True;0;0;False;0;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;238;-3015.584,243.2473;Float;False;Property;_GlitterNormalScale;Glitter Normal Scale;12;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;66;-2304.852,-600.346;Float;False;Property;_ModifiedLambertStength;Modified Lambert Stength;3;0;Create;True;0;0;False;0;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;307;-3754.945,-900.6564;Float;False;WorldPositionXZRotated;-1;;8;da1bf79f458dbcd439fd544ce19d708f;0;2;5;FLOAT;0;False;6;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;304;-3697.038,-632.212;Float;False;Property;_ModulateStrengthByDistance;Modulate Strength By Distance;8;0;Create;True;0;0;False;0;0;0;0;True;;Toggle;2;Key0;Key1;Create;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;230;-2964.49,485.6474;Float;False;Property;_CameraContribution;Camera Contribution;14;0;Create;True;0;0;False;0;0.001;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;297;-3304.109,-679.7982;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;333;-2502.264,-308.2583;Float;False;1452.677;360.1496;;9;355;354;211;213;210;208;206;205;207;Sun Specular;1,1,1,1;0;0
Node;AmplifyShaderEditor.LerpOp;316;-1994.77,-766.0801;Float;False;3;0;FLOAT;1;False;1;FLOAT;0.3;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;226;-2676.73,386.1596;Float;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;331;-2789.323,249.0101;Float;False;WorldPositionXZ;-1;;12;409d61e1d315a484388d8ae966642b06;0;1;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;102;-3438.716,-929.0623;Float;True;Property;_SandNormal;Sand Normal;4;2;[NoScaleOffset];[Normal];Create;True;0;0;False;1;Header(Sand Normals);None;None;True;0;False;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;232;-2506.543,302.2033;Float;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;249;-3100.603,-837.0583;Float;False;3;0;FLOAT3;0,0,1;False;1;FLOAT3;0,0,1;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;317;-1842.843,-788.6802;Float;False;FLOAT3;4;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;355;-2482.612,-209.8227;Float;False;Property;_SunSpecularGraininess;Sun Specular Graininess;17;0;Create;True;0;0;False;0;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;354;-2199.619,-251.5758;Float;False;3;0;FLOAT3;0,0,1;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;223;-2354.541,274.2792;Float;True;Property;_GlitterNormal;Glitter Normal;11;2;[NoScaleOffset];[Normal];Create;True;0;0;False;1;Header(Glitter);None;None;True;0;False;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;315;-1670.827,-837.6481;Float;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;319;-1571.717,-683.431;Float;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;323;-1525.064,-838.1478;Float;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;218;-2021.217,433.0235;Float;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldReflectionVector;278;-2046.644,279.4724;Float;False;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldReflectionVector;205;-2031.877,-253.161;Float;False;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;207;-2067.151,-99.27847;Float;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;206;-1791.059,-179.8332;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;217;-1770.297,414.1277;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;318;-1293.549,-780.4332;Float;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;322;-1323.505,-637.7823;Float;False;3;0;FLOAT;1;False;1;FLOAT;4;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;320;-1123.794,-713.3874;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;210;-1669.619,-60.10062;Float;False;Property;_SunSpecularExponent;Sun Specular Exponent;16;0;Create;True;0;0;False;1;Header(Sun Specular);0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LightAttenuation;338;-968.3783,-160.046;Float;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;208;-1654.403,-179.2808;Float;False;ConstantBiasScale;-1;;13;63208df05c83e8e49a48ffbdce2e43a0;0;3;3;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;221;-1666.824,532.5076;Float;False;Property;_GlitterSpecularExponent;Glitter Specular Exponent;13;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;219;-1628.845,413.6296;Float;False;ConstantBiasScale;-1;;14;63208df05c83e8e49a48ffbdce2e43a0;0;3;3;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;213;-1390.906,-140.2498;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;220;-1379.496,451.2308;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;324;-965.8778,-712.5881;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;339;-758.3783,-160.046;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;222;-1223.692,450.3458;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;211;-1224.587,-140.369;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;343;-580.1368,-161.9384;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RelayNode;352;-551.1216,-287.4248;Float;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;330;-405.8672,-285.6414;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;344;-410.1716,-183.5963;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;335;-744.7073,182.0219;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;6;-212.0362,-423.3089;Float;False;Property;_Lit;Lit;0;0;Create;True;0;0;False;1;Header(General Settings);0.9333333,0.8,0.7450981,0;0,0,0,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ToggleSwitchNode;351;-251.9449,-245.6289;Float;False;Property;_SubtractiveShadows;Subtractive Shadows;2;0;Create;True;0;0;False;0;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;69;-211.943,-604.0343;Float;False;Property;_Shadow;Shadow;1;0;Create;True;0;0;False;0;0.8862745,0.572549,0.4039216,0;0,0,0,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;337;-582.2035,60.74684;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;336;-404.7826,151.1767;Float;False;Property;_GlitterinShadows;Glitter in Shadows;15;0;Create;True;0;0;False;0;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;67;79.90273,-438.5142;Float;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;263;271.6029,134.4021;Float;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;452.7167,-94.4548;Half;False;True;2;Half;ASEMaterialInspector;0;0;CustomLighting;Stylized/Sand;False;False;False;False;True;False;True;True;True;False;True;True;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;292;0;294;0
WireConnection;292;1;293;0
WireConnection;302;0;292;0
WireConnection;300;0;302;0
WireConnection;300;1;299;0
WireConnection;303;0;300;0
WireConnection;303;1;296;0
WireConnection;298;0;303;0
WireConnection;233;0;231;0
WireConnection;307;5;106;0
WireConnection;307;6;254;0
WireConnection;304;1;305;0
WireConnection;304;0;298;0
WireConnection;297;0;250;0
WireConnection;297;1;304;0
WireConnection;316;2;66;0
WireConnection;226;0;233;0
WireConnection;226;1;230;0
WireConnection;331;1;238;0
WireConnection;102;1;307;0
WireConnection;232;0;331;0
WireConnection;232;1;226;0
WireConnection;249;1;102;0
WireConnection;249;2;297;0
WireConnection;317;1;316;0
WireConnection;354;1;249;0
WireConnection;354;2;355;0
WireConnection;223;1;232;0
WireConnection;315;0;249;0
WireConnection;315;1;317;0
WireConnection;323;0;315;0
WireConnection;278;0;223;0
WireConnection;205;0;354;0
WireConnection;206;0;205;0
WireConnection;206;1;207;0
WireConnection;217;0;278;0
WireConnection;217;1;218;0
WireConnection;318;0;323;0
WireConnection;318;1;319;0
WireConnection;322;2;66;0
WireConnection;320;0;318;0
WireConnection;320;1;322;0
WireConnection;208;3;206;0
WireConnection;219;3;217;0
WireConnection;213;0;208;0
WireConnection;213;1;210;0
WireConnection;220;0;219;0
WireConnection;220;1;221;0
WireConnection;324;0;320;0
WireConnection;339;0;338;0
WireConnection;222;0;220;0
WireConnection;211;0;213;0
WireConnection;343;0;339;0
WireConnection;352;0;324;0
WireConnection;330;0;352;0
WireConnection;330;1;339;0
WireConnection;344;0;352;0
WireConnection;344;1;343;0
WireConnection;335;0;211;0
WireConnection;335;1;222;0
WireConnection;351;0;330;0
WireConnection;351;1;344;0
WireConnection;337;0;339;0
WireConnection;337;1;335;0
WireConnection;336;0;337;0
WireConnection;336;1;335;0
WireConnection;67;0;69;0
WireConnection;67;1;6;0
WireConnection;67;2;351;0
WireConnection;263;0;67;0
WireConnection;263;1;336;0
WireConnection;0;13;263;0
ASEEND*/
//CHKSM=69C56A281270F00C45DB96CF07D19D9ED6B27F8C