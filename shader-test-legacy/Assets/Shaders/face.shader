// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/face"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _LightmapTex ("Light Map", 2D) = "white" {}
        _ShadowTex ("Shadow (RGB)", 2D) = "white" {}
        _MetcapTex ("Metcap", 2D    ) = "white" {}  
        _LightOffset("Light Offset", Float) = 0.0
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)  
        _Outline ("Outline width",Float) = .0001 
        _MetcapColor ("Metacap Color", Color) = (.5, .5, .5)
        _Skin_Bright ("Face Color Bright", Color) = (.996, .980, .976)
        _Skin_Dark ("Face Color Dark", Color) = (.956, .745, .745)
        _RimWidth ("Rim Width", Float) = 0.01
        _RimIntensity ("Rim Intensity", Float) = 1
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
                float3 front : TEXCOORD2;
                float3 lightDir : TEXCOORD3;
                float2 face_uv : TEXCOORD4; 
                float4 suv : TEXCOORD5;
                float4 pos : SV_POSITION; // clip space position
                fixed4 color : COLOR;
            };
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
            sampler2D _MainTex;
            sampler2D _LightmapTex;
            sampler2D _ShadowTex;
            sampler2D _MetcapTex;
            sampler2D _CameraDepthTexture;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _MetcapColor;
            fixed3 _Skin_Bright;
            fixed3 _Skin_Dark;
            float _LightOffset;
            float _RimWidth;
            float _RimIntensity;
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
                float flip = max(0, sign(atan2(obj_lightdir.z, obj_lightdir.x)));
                o.front = normalize(mul((float3x3)UNITY_MATRIX_M,float3(0,-1,0)));
                o.face_uv.xy = v.uv;
                o.face_uv.x = lerp(1-v.uv.x,v.uv.x, flip);
                o.color = v.color; 
                o.uv = v.uv;
                o.suv = ComputeScreenPos(o.pos);
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
                float FdotL = dot(i.front, i.lightDir);
                FdotL = (FdotL+1)/2;
                float face_ramp = aaStep(FdotL, lightmap.a);
                float2 screenUV = i.suv.xy/i.suv.w;
                float2 ufOfs = screenUV + i.normal.xy * _RimWidth;
                float depth = tex2D(_CameraDepthTexture, ufOfs).r;
                float rim = saturate(i.pos.z - depth);
                fixed3 face_color = lerp(_Skin_Dark, _Skin_Bright, face_ramp) * albedo.rgb;
                color.rgb = face_color;
                color.rgb += rim * _RimIntensity;
                color.a = 1.0;
                return color;
            }
            ENDCG
        }
        Pass 
        {  
            Name "OUTLINE"  
            Tags { "LightMode" = "Always" }  
            Cull Front  
            //Cull off  
            ZWrite On  
            //ZTest Off  
            ColorMask RGB  
            Blend SrcAlpha OneMinusSrcAlpha  
            
            //Offset 20,20    
            CGPROGRAM  
            #pragma vertex vert_outline  
            #pragma fragment frag_outline
            #include "UnityCG.cginc"
            fixed4 _OutlineColor;
            float _Outline;
            struct appdata {  
                float4 vertex : POSITION;  
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                fixed4 color : COLOR;  
            };  
            struct v2f {  
                float4 pos : POSITION;  
                float4 color : COLOR;  
            }; 
            v2f vert_outline(appdata v) {       
                v2f o;  
                o.pos = UnityObjectToClipPos(v.vertex);  
                float3 norm  = mul ((float3x3)UNITY_MATRIX_IT_MV, v.normal);  
                float2 offset = TransformViewToProjection(norm.xy);  
                float viewScaler = (o.pos.z + 1) *0.5;  
                o.pos.xy += offset * viewScaler * _Outline * v.color.a;  

                // float4 pos = UnityObjectToClipPos(v.vertex);
                // float3 norm = mul((float3x3)UNITY_MATRIX_MV, v.tangent);
                // norm.x *= UNITY_MATRIX_P[0][0];
                // norm.y *= UNITY_MATRIX_P[1][1];
                // pos.xy += norm.xy * pos.z * _Outline;
                // o.pos = pos;
                o.color.rgb = _OutlineColor;  
                return o;  
            }
            half4 frag_outline(v2f i) : COLOR   
            {  
                i.color.a = 0.9;  
                return i.color;   
            }    
            ENDCG  
        }
    
    }
         
    FallBack "Diffuse"
}
