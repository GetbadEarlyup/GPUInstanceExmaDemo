using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

public class BakingAnimation : MonoBehaviour
{
    //指定要烘培的动画
    public AnimationClip clip;
    //有动画组件的人物
    public Animator animator;
    //动画人物的蒙皮网格渲染器
    public SkinnedMeshRenderer sk;
    //总像素点
    private int pnum;
    private Texture2D texture;
    //图片的宽高
    private int size = 0;
    //总帧数
    private int frameCount;
    
    void Start()
    {
        //总帧数=动画时长*帧率
        frameCount = Mathf.CeilToInt(clip.length*30);
        Debug.Log("frameCount:"+frameCount);
        //总像素点=总顶点数*总帧数
        pnum = sk.sharedMesh.vertexCount * frameCount;
        Debug.Log("pnum:"+pnum);
        //将像素点转换成2倍数的贴图宽高
        size = Mathf.NextPowerOfTwo(Mathf.CeilToInt(Mathf.Sqrt(pnum)));
        Debug.Log("size:"+size);
        texture = new Texture2D(size,size,TextureFormat.RGBAFloat,false,true);
        //计算顶点的最大最小值
        _CalculateVertexMinAndMax(out float min,out float max);
        Debug.Log("min"+min);
        Debug.Log("max:"+max);
        //烘焙图片
        _BakeAnimationCilp(max,min);
    }

    void _BakeAnimationCilp(float max,float min)
    {
        var mesh = new Mesh();
        //计算差值
        float vertexDiff = max - min;
        //通过差值返回0-1的一个数（简易函数，传入float返回）
        Func<float, float> cal = (v) => (v - min) / vertexDiff;
        //顶点计数
        int currentPixelIndex = 0;
        //循环动画所有帧
        for (int i = 0; i < frameCount; i++)
        {
            //计算每帧时间
            float t = i * 1f / 30;
            //播放指定动画的时间
            clip.SampleAnimation(animator.gameObject,t);
            mesh.Clear(false);
            sk.BakeMesh(mesh);

            var verties = mesh.vertices;
            Debug.Log("vCount"+verties.Length);
            //循环网格的所有顶点
            for (int v = 0; v < verties.Length; v++)
            {
                var vertex = verties[v];
                //把顶点转换成0-1的颜色值
                Color c = new Color(cal(vertex.x),cal(vertex.y),cal(vertex.z));
                //一维转二维
                //通过顶点id计算该颜色在图片中的位置
                int x = currentPixelIndex % size;
                int y = currentPixelIndex / size;
                //颜色写入图片
                texture.SetPixel(x,y,c);
                currentPixelIndex++;
            }
        }
        //保存图片
        texture.Apply();
        File.WriteAllBytes(Application.dataPath+"/anim.png",texture.EncodeToPNG());
    }
    
    void _CalculateVertexMinAndMax(out float vertexMin,out float vertexMax)
    {
        //默认float最大、最小值
        float min = float.MaxValue;
        float max = float.MinValue;

        Mesh preCalMesh = new Mesh();

        for (int f= 0; f < frameCount; f++)
        {
            float t = f * 1f / 30;
            //播放指定时间动画
            clip.SampleAnimation(animator.gameObject,t);
            //取出当前人物蒙皮的网格
            sk.BakeMesh(preCalMesh);
            //循环便利所有顶点
            for (int v = 0; v < preCalMesh.vertexCount; v++)
            {
                var vertex = preCalMesh.vertices[v];
                //取x,y,z的最小值
                //min=Mathf.Floor（Mathf.Min(min,vertex.x,vertex.y,vertex.z)）
                min = Mathf.Min(min,vertex.x,vertex.y,vertex.z);
                //取x,y,z的最大值
                //min=Mathf.Ceil（Mathf.Min(min,vertex.x,vertex.y,vertex.z)）
                max = Mathf.Max(max,vertex.x,vertex.y,vertex.z);
            }
        }

        vertexMin = min;
        vertexMax = max;
    }
    
}
