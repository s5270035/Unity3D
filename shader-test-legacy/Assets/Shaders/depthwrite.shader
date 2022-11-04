// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/DepthWrite" {
    Properties {
        _MainTex ("Base (RGB)", 2D) = "black" {}
    }
SubShader {
    Pass {
        ZTest Always Cull Off ZWrite On
      Fog { Mode off }
        
        CGPROGRAM        
            #pragma exclude_renderers gles flash
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.0
             #include "UnityCG.cginc" 
            // vertex input: position, UV
            struct appdata {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };
           
            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
           
            v2f vert (appdata v) {
                v2f o;
                o.pos = UnityObjectToClipPos( v.vertex );
                o.uv = v.texcoord.xy;
                return o;
            }
           

            
            sampler2D _MainTex;     
            sampler2D _CameraDepthTexture;
            
            
            struct fragOut
           {
               // half4 color : COLOR;   don't need
               float depth : DEPTH;
            };
          
            fragOut frag( v2f i ) {
                fragOut o;
                float depth =UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture,i.uv));
                o.depth= depth;
                return o;
           }
            
        ENDCG
        }
    }
}