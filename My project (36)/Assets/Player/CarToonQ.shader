Shader "CarToonQ"
{
    Properties
    {
        // 颜色
        _Color("Color", Color) = (1, 1, 1, 1)
        _HColor("Highlight Color", Color) = (0.9, 0.9, 0.9, 1.0)
        _SColor("Shadow Color", Color) = (0.4, 0.4, 0.4, 1.0)

        // 贴图
        _MainTex("Main Texture", 2D) = "white" { }
        _FaceTex("Face Texture", 2D) = "white" { }

        //缩放
        _ScaleX("ScaleX",Float) = 4
        _ScaleY("ScaleY",Float) = 4

        //偏移
        _PosX("PosX",Float) = -0.2
        _PosY("PosY",Float) = 0

        // 渐变
        _ToonSteps("Steps of Toon", range(1, 9)) = 2
        _RampThreshold("Ramp Threshold", Range(0.1, 1)) = 0.7
        _RampSmooth("Ramp Smooth", Range(0, 1)) = 0.5

        // 镜面
        _SpecColor("Specular Color", Color) = (0, 0, 0, 1)
        _SpecSmooth("Specular Smooth", Range(0, 1)) = 0
        _Shininess("Shininess", Range(0.001, 10)) = 0.9

        // 边缘
        _RimColor("Rim Color", Color) = (0.1, 0.1, 0.1, 0.5)
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.5
        _RimSmooth("Rim Smooth", Range(0, 1)) = 1
    }

        SubShader
    {
        Tags { "RenderType" = "Opaque" }

        CGPROGRAM

        #pragma surface surf Toon addshadow fullforwardshadows exclude_path:deferred exclude_path:prepass
        #pragma target 3.0
        // 基础色
        fixed4 _Color;
        // 高光颜色
        fixed4 _HColor;
        // 阴影色
        fixed4 _SColor;
        // 主贴图
        sampler2D _MainTex;
        // 脸贴图
        sampler2D _FaceTex;
        // 脸缩放X
        float _ScaleX;
        // 脸缩放Y
        float _ScaleY;
        // 脸偏移X
        float _PosX;
        // 脸偏移Y
        float _PosY;
        // 渐变阈值
        float _RampThreshold;
        // 渐变平滑度
        float _RampSmooth;
        // 渐变阶数
        float _ToonSteps;
        // 镜面平滑度
        float _SpecSmooth;
        // 光滑度
        fixed _Shininess;
        // 边缘颜色
        fixed4 _RimColor;
        // 边缘阈值
        fixed _RimThreshold;
        // 边缘光滑度
        float _RimSmooth;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
        };

        // 线性阶跃
        float linearstep(float min, float max, float t)
        {
            return saturate((t - min) / (max - min));
        }

        inline fixed4 LightingToon(SurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
        {
            half3 normalDir = normalize(s.Normal);
            half3 halfDir = normalize(lightDir + viewDir);

            float ndl = max(0, dot(normalDir, lightDir));
            float ndh = max(0, dot(normalDir, halfDir));
            float ndv = max(0, dot(normalDir, viewDir));

            // 平滑阶跃
            float diff = smoothstep(_RampThreshold - ndl, _RampThreshold + ndl, ndl);
            float interval = 1 / _ToonSteps;
            // float ramp = floor(diff * _ToonSteps) / _ToonSteps;
            float level = round(diff * _ToonSteps) / _ToonSteps;
            float ramp;
            if (_RampSmooth == 1)
            {
                ramp = interval * linearstep(level - _RampSmooth * interval * 0.5, level + _RampSmooth * interval * 0.5, diff) + level - interval;
            }
            else
            {
                ramp = interval * smoothstep(level - _RampSmooth * interval * 0.5, level + _RampSmooth * interval * 0.5, diff) + level - interval;
            }
            ramp = max(0, ramp);
            ramp *= atten;

            _SColor = lerp(_HColor, _SColor, _SColor.a);
            float3 rampColor = lerp(_SColor.rgb, _HColor.rgb, ramp);

            // 镜面
            float spec = pow(ndh, s.Specular * 128.0) * s.Gloss;
            spec *= atten;
            spec = smoothstep(0.5 - _SpecSmooth * 0.5, 0.5 + _SpecSmooth * 0.5, spec);

            // 边缘
            float rim = (1.0 - ndv) * ndl;
            rim *= atten;
            rim = smoothstep(_RimThreshold - _RimSmooth * 0.5, _RimThreshold + _RimSmooth * 0.5, rim);

            fixed3 lightColor = _LightColor0.rgb;

            fixed4 color;
            fixed3 diffuse = s.Albedo * lightColor * rampColor;
            fixed3 specular = _SpecColor.rgb * lightColor * spec;
            fixed3 rimColor = _RimColor.rgb * lightColor * _RimColor.a * rim;

            color.rgb = diffuse + specular + rimColor;
            color.a = s.Alpha;
            return color;
        }

        // 表面着色器
        void surf(Input IN, inout SurfaceOutput o)
        {
            fixed4 mainTex = tex2D(_MainTex, IN.uv_MainTex);

            float2 uv = float2(IN.uv_MainTex.x * _ScaleX, IN.uv_MainTex.y * _ScaleY) + float2(_PosX, _PosY);
            fixed4 faceTex = tex2D(_FaceTex, uv);

            fixed4 col = lerp(mainTex, faceTex, faceTex.a);

            o.Albedo = col.rgb * _Color.rgb;

            o.Alpha = col.a * _Color.a;

            o.Specular = _Shininess;
            o.Gloss = col.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
