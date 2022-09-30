// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/body"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _LightmapTex ("Light Map", 2D) = "white" {}
        _RampTex ("Ramp (RGB)", 2D) = "white" { }  
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            // vertex shader
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normal = normalize(v.normal);
                o.viewDir = normalize(ObjSpaceViewDir(v.vertex));
                o.lightDir = normalize(ObjSpaceLightDir(v.vertex));
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float NoL = dot(i.normal, i.lightDir);
                float half_lambert = NoL * 0.5 + 0.5;
                fixed4 col = 1;
                fixed4 white = 1;
                float s = GGXNormalDistribution(0.01, i.lightDir, i.viewDir, i.normal);
                col = s;
                col.a = 1.0;
                return col;
            }
            ENDCG
        }
    
    }
         
    FallBack "Diffuse"
}
