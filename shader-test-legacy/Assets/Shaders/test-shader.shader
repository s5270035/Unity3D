// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/test-shader"
{
    Properties
    {
        _Color ("Main Color", Color) = (1, 1, 1, 1)
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            // vertex shader inputs
            struct appdata
            {
                float4 vertex : POSITION; // vertex position
                float3 normal : NORMAL;   // texture coordinate
            };
        
            // vertex shader outputs ("vertex to fragment")
            struct v2f
            {
                // float2 uv : TEXCOORD0; // texture coordinate
                half3 worldRefl : TEXCOORD0;
                UNITY_FOG_COORDS(1)
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
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                
                o.worldRefl = reflect(-worldViewDir, worldNormal);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, i.worldRefl);
                half3 skyColor = DecodeHDR (skyData, unity_SpecCube0_HDR);
                fixed4 col = 0;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                col.rgb = skyColor;
                return col;
            }
            ENDCG
        }
    }
}
