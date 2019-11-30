Shader "Stylized/Sand (Simple)"
{
    Properties
    {
        [Header(Colors)]
        _NearColor ("Near", Color) = (0.9333333, 0.8, 0.7450981)
        _FarColor ("Far", Color) = (0.8509804, 0.3882353, 0.1411765)
        _ShadowColor ("Shadows", Color) = (0.745283, 0.5526814, 0.3410021)

        [Header(Parameters)]
        _ShadowStrength ("Shadow Strength", Range(0, 1)) = 0.15
        [Toggle]
        _ApplyFog ("Apply Fog", int) = 0
        _DistanceScale ("Distance Scale", float) = 175
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // For fog.
            #pragma multi_compile_fog

            // TODO: fix light attenuation on osx/metal.
            // #pragma multi_compile_fwdbase 
            // #include "AutoLight.cginc" 

            float3 _NearColor;
            float3 _FarColor;
            float3 _ShadowColor;

            float _ShadowStrength;
            uint _ApplyFog;
            float _DistanceScale;

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPosition : TEXCOORD0;
                float3 worldNormal : TEXCOORD1; 
                UNITY_FOG_COORDS(2)
            };

            v2f vert (float4 vertex : POSITION, float3 normal : NORMAL)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(vertex);
                o.worldPosition = mul(unity_ObjectToWorld, vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(normal);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Lit color.
                float dist = length(i.worldPosition - _WorldSpaceCameraPos);
                fixed3 colorLit = lerp(_NearColor, _FarColor, saturate(dist / _DistanceScale));

                // Shaded color.
                float shadowMask = lerp(1, saturate(dot(i.worldNormal, _WorldSpaceLightPos0.xyz)), _ShadowStrength);
                fixed3 colorShaded = lerp(_ShadowColor, 1, shadowMask);

                // Calculate the final color.
                fixed3 color = colorLit * colorShaded;

                // Apply fog.
                fixed3 colorFogged = color;
                UNITY_APPLY_FOG(i.fogCoord, colorFogged);

                return fixed4(lerp(color, colorFogged, _ApplyFog), 1);
            }
            ENDCG
        }
    }
}
