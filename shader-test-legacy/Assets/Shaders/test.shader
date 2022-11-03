Shader "Custom/test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            #include "UnityStandardBRDF.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.normal = UnityObjectToWorldNormal(v.normal);
                //o.normal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV,v.normal));
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float4 wordPos = mul(unity_ObjectToWorld, v.vertex);
                float4 worldLight = mul(UNITY_MATRIX_M,v.vertex);
                o.lightDir = normalize(WorldSpaceLightDir(v.vertex));
                //float3 lightdir = normalize(ObjSpaceLightDir(v.vertex));
                //o.lightDir = lightdir;
                //o.lightDir = normalize(mul((float3x3)UNITY_MATRIX_MV, lightdir));
                //float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
                //o.viewDir = viewDir;
                //o.viewDir = normalize(mul((float3x3)UNITY_MATRIX_MV,viewDir));

               
                o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float3 right = unity_ObjectToWorld._m00_m10_m20;
                float h = Unity_SafeNormalize(i.lightDir+i.viewDir);
                float cosThetaO = i.lightDir.y;
                float cosThetaI = i.viewDir.y;
                float LdotH = max(0, dot(i.lightDir, h));
                float NdotV = max(0, dot(i.normal, i.viewDir));
                float NdotL = max(0, dot(i.normal, i.lightDir));
                float NdotH = max(0, dot(i.normal, h));

                float roughness = 0.1;
                roughness = max(roughness, 0.002);
                float V = SmithJointGGXVisibilityTerm (NdotL, NdotV, roughness);
                float D =  GGXTerm (NdotH, roughness);
                float a = any(col);
                col.rgb = 0;
                float specularterm = V*D*UNITY_PI;

                //if(NdotL > 0) {
                    col.rgb = FresnelTerm(half3(0.5, 0.5, 0.5), LdotH) * NdotL;
                   // col.rgb = pow(1-LdotH,5);
               // }

                
                //col.rgb = pow(1-LdotH, 5);
                return col;
            }
            ENDCG
        }
    }
}
