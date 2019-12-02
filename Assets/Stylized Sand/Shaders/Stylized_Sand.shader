Shader "Stylized/Sand"
{
    Properties
    {


        [Header(Shading)]
        _LitColor ("Lit", Color) = (0.9339623, 0.8018943, 0.7445265)
        _ShadedColor ("Shadow", Color) = (0.8867924, 0.5717139, 0.4057494)
        _ModifiedLambertStrength ("Shadow Exaggeration", Range(0, 1)) = 0.25
        [Toggle]
        _ApplyFog ("Apply Fog", int) = 0

        [Header(Dunes)]
        [NoScaleOffset]
        _DunesNormalMap ("Normal Map", 2D) = "bump" {}
        _DunesScale ("Scale", float) = 10
        _DunesStrength ("Strength", Range(0, 1)) = 1

        [Header(Sun Specular)]
        _SunSpecGraininess ("Graininess", Range(0, 1)) = 0.4
        _SunSpecExp ("Exponent", float) = 250
        [Toggle]
        _SunSpecInShadows ("Visible in Shadows", int) = 0

        [Header(Glitter Specular)]
        [NoScaleOffset]
        _GlitterNormalMap ("Normal Map", 2D) = "bump" {}
        _GlitterScale ("Scale", float) = 15
        _CameraContribution ("Camera Contribution", Range(0, 0.1)) = 0.001
        _GlitterSpecGraininess ("Graininess", Range(0, 1)) = 1
        _GlitterSpecExp ("Exponent", float) = 100
        [Toggle]
        _GlitterSpecInShadows ("Visible in Shadows", int) = 0

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

            sampler2D _DunesNormalMap;
            float _DunesScale;
            float _DunesStrength;
            uint _ApplyFog;

            float3 _LitColor;
            float3 _ShadedColor;
            float _ModifiedLambertStrength;

            float _SunSpecGraininess;
            float _SunSpecExp;
            uint _SunSpecInShadows;

            sampler2D _GlitterNormalMap;
            float _GlitterScale;
            float _CameraContribution;
            float _GlitterSpecGraininess;
            float _GlitterSpecExp;
            uint _GlitterSpecInShadows;

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPosition : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldTangent : TEXCOORD2;
                UNITY_FOG_COORDS(3)
            };

            v2f vert (float4 vertex : POSITION, float3 normal : NORMAL, float4 tangent : TANGENT)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(vertex);
                o.worldPosition = mul(unity_ObjectToWorld, vertex).xyz;
                o.worldNormal = normalize(UnityObjectToWorldNormal(normal));
                o.worldTangent = normalize(UnityObjectToWorldDir(tangent).xyz);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            float3x3 constructTangentToWorldMatrix(v2f i)
            {
                // Construct the TBN matrix.
                float3x3 worldToTangent = float3x3(i.worldTangent, normalize(cross(i.worldNormal, i.worldTangent)), i.worldNormal);

                // The TBN matrix forms an orthonormal basis, so the inverse is the transpose.
                float3x3 tangentToWorld = transpose(worldToTangent);
                return tangentToWorld;
            }

            float4 frag (v2f i) : SV_Target
            {
                // Construct tangent-to-world matrix.
                float3x3 tangentToWorld = constructTangentToWorldMatrix(i);  // transpose(float3x3(i.worldTangent, normalize(cross(i.worldNormal, i.worldTangent)), i.worldNormal));
                
                // Unpack the dune normal map texture and scale it based on the strength.
                float3 duneNormalTS = UnpackNormal(tex2D(_DunesNormalMap, i.worldPosition.xz / _DunesScale));
                duneNormalTS = lerp(float3(0, 0, 1), duneNormalTS, _DunesStrength);
                
                // Unpack the glitter normal map texture.
                float3 glitterNormalTS = UnpackNormal(tex2D(_GlitterNormalMap, i.worldPosition.xz/_GlitterScale - _WorldSpaceCameraPos.xz*_CameraContribution));

                // Calculate the viewing direction, for specular reflections.
                float3 viewDirWS = normalize(i.worldPosition - _WorldSpaceCameraPos);
                float3 normalForSpec, viewDirRef;

                // Sun specular.
                normalForSpec = mul(tangentToWorld, duneNormalTS);
                normalForSpec = lerp(i.worldNormal, normalForSpec, _SunSpecGraininess);
                viewDirRef = reflect(viewDirWS, normalForSpec);
                float sunSpec = pow(saturate(dot(viewDirRef, _WorldSpaceLightPos0.xyz)), _SunSpecExp);
                
                // Glitter specular.
                normalForSpec = mul(tangentToWorld, glitterNormalTS);
                normalForSpec = lerp(i.worldNormal, normalForSpec, _GlitterSpecGraininess);
                viewDirRef = reflect(viewDirWS, normalForSpec);
                float glitterSpec = pow(saturate(dot(viewDirRef, _WorldSpaceLightPos0.xyz)), _GlitterSpecExp);

                // Shadow mask.
                float3 normalForShadows = mul(tangentToWorld, duneNormalTS * float3(1, lerp(1, 0.3, _ModifiedLambertStrength), 1));
                float shadowMask = saturate(dot(normalForShadows, _WorldSpaceLightPos0.xyz));
                shadowMask = 1 - saturate(shadowMask * lerp(1, 4, _ModifiedLambertStrength));

                // Apply shadow mask to specular values.
                sunSpec *= lerp(1, _SunSpecInShadows, shadowMask);
                glitterSpec *= lerp(1, _GlitterSpecInShadows, shadowMask);

                // Calculate the final color.
                float3 color = lerp(_LitColor, _ShadedColor, shadowMask) + (sunSpec + glitterSpec);

                // Apply fog, if enabled.
                float3 colorFogged = color;
                UNITY_APPLY_FOG(i.fogCoord, colorFogged);

                return float4(lerp(color, colorFogged, _ApplyFog), 1);
            }
            ENDCG
        }
    }
}
