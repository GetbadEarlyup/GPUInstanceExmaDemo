Shader "Unlit/MyGPUInstance"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FaceTex ("Face", 2D) = "white" {}
        _FaceVec ("FaceVec", Vector) = (0,0,0,0)
        //生成的信息贴图
        _AnimTex("Anim", 2D) = "white" {}
        _Fmax("fmax",Float)=87
        _VCount("vCount",Float)=3466
        _Size("size",Float)=1024
        _VertexMax("VertexMax",Float)=2
        _VertexMin("VertexMin",Float)=1

        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            //第一步 shader增加变体使用shader可以支持instance
            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float4,_Color)
            UNITY_DEFINE_INSTANCED_PROP(float,_Phi)
            UNITY_INSTANCING_BUFFER_END(Props)

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                //返回顶点id
                uint vid:SV_VertexID;

                //第二步：instanceId 加入定点着色器输入结构
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;

                //第三步：instanceId 加入定点着色器输入结构
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _MainTex;
            sampler2D _FaceTex;
            sampler2D _AnimTex;
            uint _Fmax;
            uint _VCount;
            float _Size;
            float _VertexMax;
            float _VertexMin;
            float4 _MainTex_ST;
            float4 _FaceVec;

            v2f vert (appdata v)
            {
                v2f o;
                //第四步 instanceid在定点的相关设置
                UNITY_SETUP_INSTANCE_ID(v);
                //第五步 传递 instanceid 顶点到片元
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                //当前帧数
                uint f = fmod(ceil(_Time.y * 30), _Fmax);
                    //当前顶点
                uint index = v.vid + f * _VCount;

                //计算当前顶点在图片中的xy坐标
                uint x = index % (uint)_Size;
                uint y = index /_Size;
                //把xy坐标转换0到1的uv坐标
                float uvx = x / _Size;
                float uvy = y / _Size;
                //获取图片中的uv坐标的颜色 赋值给顶点坐标
                v.vertex = tex2Dlod(_AnimTex, float4(uvx, uvy, 0, 0)) * (_VertexMax - _VertexMin) + _VertexMin;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //第六步 ：instaceid在片元的相关设置
                 UNITY_SETUP_INSTANCE_ID(i);
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                //设置脸
                fixed4 face = tex2D(_FaceTex, float2(i.uv.x*_FaceVec.x+_FaceVec.z,i.uv.y* _FaceVec.y+ _FaceVec.w));
                col = lerp(col, face, face.a);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}