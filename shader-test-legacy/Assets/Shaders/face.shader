// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/face"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _LightmapTex ("Light Map", 2D) = "white" {}
        _ShadowTex ("Shadow (RGB)", 2D) = "white" {}
        _MetcapTex ("Metcap", 2D    ) = "white" {}  
        _MetcapColor ("Metacap Color", Color) = (.5, .5, .5)
        _Skin_Bright ("Face Color Bright", Color) = (.996, .980, .976)
        _Skin_Dark ("Face Color Dark", Color) = (.956, .745, .745)
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
                float4 right : TEXCOORD2;
                float3 lightDir : TEXCOORD3;
                float2 face_uv : TEXCOORD4; 
                float4 pos : SV_POSITION; // clip space position
                fixed4 color : COLOR;
            };

            sampler2D _MainTex;
            sampler2D _LightmapTex;
            sampler2D _ShadowTex;
            sampler2D _MetcapTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _MetcapColor;
            fixed3 _Skin_Bright;
            fixed3 _Skin_Dark;
            static const float EPSILON = 0.0001;
            // vertex shader
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV,v.normal));
                float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
                float3 obj_lightdir = normalize(ObjSpaceLightDir(v.vertex));
                float3 lightdir = normalize(WorldSpaceLightDir(v.vertex));
                o.lightDir = lightdir;
                float flip = step(0, sign(atan2(obj_lightdir.z, obj_lightdir.x)));
                o.right.w = (sign(dot(float3(0,1,0), obj_lightdir))+1)/2;
                o.right.xyz = normalize(mul((float3x3)UNITY_MATRIX_M,float3(0,0,1))) * (flip*2-1);
                o.face_uv.xy = v.uv;
                o.face_uv.x = lerp(1-v.uv.x, v.uv.x, flip);
                o.color = v.color;
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 albedo = tex2D(_MainTex, i.uv);
                float4 lightmap = tex2D(_LightmapTex, i.face_uv);
                float2 matcapUV = i.normal * 0.5 + 0.5;
                float4 matcap = tex2D(_MetcapTex, matcapUV);         

                float skin = 1 - step(lightmap.a, 0.95);

                fixed4 shadow = tex2D(_ShadowTex, i.uv);                
                float4 color = 1;
                float RdotL = dot(i.right.xz, i.lightDir.xz);
                float face_ramp = step(RdotL, lightmap.g) * i.right.w;
                //face_ramp = lerp(face_ramp, smoothstep(RdotL-0.015, RdotL+0.015, lightmap.g) * i.right.w, 0.7);
                fixed3 face_color = lerp(_Skin_Dark, _Skin_Bright, face_ramp) * albedo.rgb;
                color.rgb = face_color;
                color.a = 1.0;
                return color;
            }
            ENDCG
        }
    
    }
         
    FallBack "Diffuse"
}
