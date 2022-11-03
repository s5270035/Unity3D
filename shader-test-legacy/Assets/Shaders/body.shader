// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/body"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _LightmapTex ("Light Map", 2D) = "white" {}
        _RampTex ("Ramp (RGB)", 2D) = "white" {}
        _MetcapTex ("Metcap", 2D    ) = "white" {}  
        _MetcapColor ("Metacap Color", Color) = (.5, .5, .5)
        _RampOffset ("Offset unit scale", Float) = 0.5
        _Alpha0 ("Alpha 0 id", Float) = 0
        _Alpha1 ("Alpha 1 id", Float) = 1
        _Alpha0_5 ("Alpha 0.5 id", Float) = 2
        _Alpha0_7 ("Alpha 0.7 id", Float) = 3
        _Diffuse_step_A ("Diffuse step begin", Float) = 0.45
        _Diffuse_step_B ("Diffuse step end", Float) = 0.5
        _Shadow_step_A ("Diffuse step begin", Float) = 0.13
        _Shadow_step_B ("Diffuse step begin", Float) = 0.35
        
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
            //#include "ggx.glslinc"
            #include "UnityStandardBRDF.cginc"
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
            float _Alpha0;
            float _Alpha1;
            float _Alpha0_5;
            float _Alpha0_7;
            fixed4 _MetcapColor;
            float _RampOffset;
            float _Diffuse_step_A;
            float _Diffuse_step_B;
            float _Shadow_step_A;
            float _Shadow_step_B;
            float aaStep(float compValue, float gradient){
                float halfChange = fwidth(gradient) / 2;
                //base the range of the inverse lerp on the change over one pixel
                float lowerEdge = compValue - halfChange;
                float upperEdge = compValue + halfChange;
                //do the inverse interpolation
                float stepped = (gradient - lowerEdge) / (upperEdge - lowerEdge);
                stepped = saturate(stepped);
                return stepped;
            }
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
                o.lightDir = lightdir;
                o.lightDir = normalize(mul((float3x3)UNITY_MATRIX_MV, lightdir));
                float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
                o.viewDir = viewDir;
                o.viewDir = normalize(mul((float3x3)UNITY_MATRIX_MV,viewDir));
                o.color = v.color;
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 h = Unity_SafeNormalize(i.lightDir + i.viewDir);
                fixed4 white = 1;
                float NdotV = max(0, dot(i.normal, i.viewDir));
                float NdotH = max(0, dot (i.normal, h));
                float NdotL = max(0, dot (i.normal, i.lightDir));
                // float VdotH = max(0, dot(i.viewDir, h));
                float LdotH = saturate(dot(i.lightDir, h));
                
                float RampPixelY = 0.05; // 1/10/2 = 0.05
                float RampPixelX = 0.00390625; // 1.0/256.0
                float RampOffsetMask = i.color.g;
                float4 albedo = tex2D(_MainTex, i.uv);
                float4 lightmap = tex2D(_LightmapTex, i.uv);
                float2 matcapUV = i.normal * 0.5 + 0.5;
                float4 matcap = tex2D(_MetcapTex, matcapUV);
                float halfLambert = NdotL * 0.5 + 0.5 ;
                float LayerMask = lightmap.a;
                float ShadowAOMask = lightmap.g;
                float matcap_value =  clamp(smoothstep(0, 0.5, matcap.r) , 0, 1);
                // choice ramp
                float RampIndex = lerp(
	                    lerp(_Alpha0, _Alpha0_5, step(0.45, LayerMask)), 
                        lerp(_Alpha0_7, _Alpha1, step(0.95, LayerMask)),
	                    step(0.65, LayerMask)             
                    );
                float ramp_offset = max(0, 1 - ((RampIndex)/10+0.05));
                ShadowAOMask = smoothstep(_Shadow_step_A, _Shadow_step_B, lightmap.g);
                halfLambert = smoothstep(_Diffuse_step_A, _Diffuse_step_B, halfLambert);
                float matcap_mask = aaStep(0.8, lightmap.b+lightmap.r);
                fixed3 matcap_color = lerp(white, _MetcapColor, 1-matcap_value);
                matcap_color = lerp(white, matcap_color, matcap_mask);
                float3 ramp = tex2D(_RampTex, float2(halfLambert*ShadowAOMask, ramp_offset));                
                float4 color = 1;
                float roughness = max(0.04, 1 - lightmap.r);
                half V = SmithJointGGXVisibilityTerm(NdotL, NdotV, roughness);
                half D = GGXTerm (NdotH, roughness);
                float specular_term = V*D*UNITY_PI;
                specular_term = max(0, specular_term * NdotL);
                fixed3 specularColor = lerp(0.1, albedo.rgb * lightmap.b, 1-lightmap.a);
                color.rgb =   ramp*albedo.rgb*matcap_color +specular_term * FresnelTerm(specularColor, LdotH);
                color.a = 1.0;
                return color;
            }
            ENDCG
        }
    
    }
         
    FallBack "Diffuse"
}
