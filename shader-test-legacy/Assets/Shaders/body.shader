// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/body"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _LightmapTex ("Light Map", 2D) = "white" {}
        _RampTex ("Ramp (RGB)", 2D) = "white" {}
        _MetcapTex ("Metcap", 2D    ) = "white" {}  
        _RampOffset ("Offset unit scale", Float) = 0.5
        _ShadowSmooth ("Shadow Smooth", Float) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "ggx.glslinc"
            // vertex shader inputs
            struct appdata
            {
                float4 vertex : POSITION; // vertex position
                float3 normal : NORMAL;  
                float2 uv : TEXCOORD0;  // texture coordinate
                fixed4 color : COLOR;
            };
        
            // vertex shader outputs ("vertex to fragment")
            struct v2f
            {
                float2 uv : TEXCOORD0; // texture coordinate
                float3 normal : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                float3 lightDir : TEXCOORD3;
                float4 pos : SV_POSITION; // clip space position
                fixed4 color : COLOR;
            };

            sampler2D _MainTex;
            sampler2D _LightmapTex;
            sampler2D _RampTex;
            sampler2D _MetcapTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _RampOffset;
            float _ShadowSmooth;
            // vertex shader
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // o.normal = normalize(v.normal);
                // o.viewDir = normalize(ObjSpaceViewDir(v.vertex));
                // o.lightDir = normalize(ObjSpaceLightDir(v.vertex));
                o.normal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV,v.normal));
                float3 lightdir = normalize(ObjSpaceLightDir(v.vertex));
                o.lightDir = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, lightdir));
                float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
                o.viewDir = normalize(mul((float3x3)UNITY_MATRIX_IT_MV,viewDir));
                o.color = v.color;
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 h = normalize (i.lightDir + i.viewDir);
                fixed4 white = 1;
                float NdotV = max(0, dot(i.normal, i.viewDir));
                float NdotH = max(0, dot (i.normal, h));
                float NdotL = max(0, dot (i.normal, i.lightDir));
                // float VdotH = max(0, dot(i.viewDir, h));
                // float LdotH = max(0, dot(i.lightDir, h));
                float Roughness = 0.5;
                // float specular_D = D_GTR1(Roughness, NdotH);
                
                float RampPixelY = 0.05; // 1/10/2 = 0.05
                float RampPixelX = 0.00390625; // 1.0/256.0
                float RampOffsetMask = i.color.g;
                float4 albedo = tex2D(_MainTex, i.uv);
                float4 lightmap = tex2D(_LightmapTex, i.uv);
                float2 matcapUV = i.normal * 0.5 + 0.5;
                float4 matcap = tex2D(_MetcapTex, matcapUV);
                //float halfLambert = smoothstep(0.0,0.5,NdotL) * lightmap.b;
                //float halfLambert = (NdotL *0.5 + 0.5 + RampOffsetMask - 1) / _RampOffset;
                float halfLambert = NdotL * 0.5 + 0.5 ;
                // float halfLambert2;
                // halfLambert2 = halfLambert * _RampOffset / (_RampOffset + 0.22);
                // halfLambert = smoothstep(0, _ShadowSmooth, halfLambert);
                // halfLambert2 = smoothstep(0, _ShadowSmooth, halfLambert2);
                // halfLambert = clamp(halfLambert, RampPixelX, 1 - RampPixelX);
                // halfLambert2 = clamp(halfLambert2, RampPixelX, 1 - RampPixelX);
                
                // halfLambert = smoothstep(0.0,0.5,halfLambert);
                //float s = smithG_GGX(NdotV, 0.25);
                // float3 diffuse = Diffuse_Burley_Disney(white, Roughness, NdotV, NdotL, LdotH);
                // float FD90 = 0.5 + 2 * LdotH * LdotH * Roughness; 
                // float FL = SchlickFresnel(NdotL);
                // float FV = SchlickFresnel(NdotV);
                // diffuse = mix(1.0, FD90, FL) * mix(1.0, FD90, FV)* 1/3.1415 * white; 
                float RampIndex = 1;
                float LayerMask = lightmap.a;
                if (LayerMask >= 0 && LayerMask <= 0.3) // metal ? 0
                {
                    RampIndex = 0;
                }
                if (LayerMask >= 0.4 && LayerMask <=0.6) // cloth? 0.5
                {
                    RampIndex = 1;
                }
                if (LayerMask >= 0.6 && LayerMask <=0.8) // hard suface ? 0.7
                {
                    RampIndex = 2;
                }

                if (LayerMask >= 0.9 && LayerMask <= 1.0) // skin 1
                {
                    RampIndex = 3;
                }
                float PixelInRamp = 1 - RampPixelY * (2 * RampIndex - 1);
                float ShadowAOMask = lightmap.g;
                float matcap_value =  clamp(smoothstep(0, 0.5, matcap.r) + i.color.g, 0, 1);
                ShadowAOMask = smoothstep(0, 0.3, lightmap.g);
                // halfLambert = smoothstep(_RampOffset, _RampOffset+RampPixelX*20, halfLambert);
                halfLambert = smoothstep(0, 0.8, halfLambert);
                float3 ramp = tex2D(_RampTex, float2(halfLambert*ShadowAOMask*matcap_value, 0.25));
                float3 metal_ramp = tex2D(_RampTex, float2(halfLambert*ShadowAOMask*matcap_value, 0.95)) ;
                float3 skin_ramp =  tex2D(_RampTex, float2(halfLambert*ShadowAOMask, 0.85));
                float3 ramp_matcap = tex2D(_RampTex, float2(matcap_value*ShadowAOMask, 0.35));
                float3 BaseMapShadowed = lerp(albedo.rgb * ramp, albedo.rgb, ShadowAOMask);
                ramp_matcap = clamp(ramp_matcap+0.2, 0, 1);
                float4 color = 1;
                float metal = step(lightmap.a, 0.1);
                float skin = 1 - step(lightmap.a, 0.9);
                float glossiness = max(50*lightmap.r, 1);
                float specular = pow(NdotH, glossiness) * lightmap.b;
                fixed3 specular_color = specular*metal + (1-metal) * specular;
                fixed3 diffuse_color = (1-metal) * (albedo.rgb*skin*skin_ramp + (1-skin) * albedo.rgb*ramp*ramp_matcap);
                specular_color = albedo.rgb * metal * metal_ramp + specular_color ;
                //float rim = pow(1- NdotV, 5);
                float rim = smoothstep(0.6, 1, 1-NdotV)/2;
                color.rgb = specular_color+diffuse_color;
                //color.rgb = lightmap.a;
                color.a = 1.0;
                return color;
            }
            ENDCG
        }
    
    }
         
    FallBack "Diffuse"
}
