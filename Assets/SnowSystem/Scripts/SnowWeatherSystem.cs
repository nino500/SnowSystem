using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SnowWeatherSystem : MonoBehaviour
{
    [Header("头顶相机记录高度图")]
    public Camera topDownCamera;
    public GameObject target;
    public float maxWorldY = 35f;
    public float minWordY = 0f;
    public RenderTexture heightRT;

    [Header("覆雪参数")] public float _GlobalSnowProgress = 0.4f;//全局雪进度

    public float maxSnowThickness = 1.0f;
    


//id转换
    //高度RT参数
   private readonly int snowWorldAreaId = Shader.PropertyToID("_SnowWorldArea");
   private readonly int topDownHeightRangeId = Shader.PropertyToID("_TopDownHeightRange");
   private readonly int _TopDownHeightRTId = Shader.PropertyToID("_TopDownHeightRT");
   
   //雪地参数
   private readonly int _GlobalSnowCoverageId = Shader.PropertyToID("_GlobalSnowCoverage");  
   private readonly int GlobalSnowThicknessId = Shader.PropertyToID("_GlobalSnowThickness");

    
    void Start()
    {
        Setup();
    }


    void Setup()
    {
        
        
        
        if (topDownCamera == null||heightRT == null) return;
        
        Vector3 targetPosition = target.transform.position;
        float GroundSize = target.GetComponent<MeshCollider>().bounds.size.x;
        
        topDownCamera.orthographic = true;
        topDownCamera.orthographicSize = GroundSize / 2.0f;


        topDownCamera.transform.position = new Vector3(targetPosition.x,maxWorldY,targetPosition.z);

        topDownCamera.transform.rotation = Quaternion.Euler(90f, 0f, 0f);
        
        topDownCamera.nearClipPlane = 0.1f;
        topDownCamera.farClipPlane = maxWorldY - minWordY + 5f;

        topDownCamera.clearFlags = CameraClearFlags.SolidColor;
        topDownCamera.backgroundColor = Color.black;
        
        
        Vector4 _SnowWorldArea = new Vector4(targetPosition.x,targetPosition.z,GroundSize,1f/GroundSize); //xy为场景中心位置， z为区域边长，w为1/边长
        Vector4 _TopDownHeightRange =  new Vector4(minWordY-5f,maxWorldY-0.1f,0.0f,0.0f);//相机深度范围.x为底面高度，y为总范围
        
 

        //上传全局参数
        Shader.SetGlobalVector(snowWorldAreaId,_SnowWorldArea);
        Shader.SetGlobalVector(topDownHeightRangeId,_TopDownHeightRange);
        Shader.SetGlobalTexture(_TopDownHeightRTId,heightRT);
    }

    void Update()
    {        
        
        float _GlobalSnowCoverage  = Mathf.Clamp01(_GlobalSnowProgress/0.4f);
        float SnowThicknessFactor = Mathf.Clamp01((_GlobalSnowProgress-0.4f)/0.6f);
        
        Shader.SetGlobalFloat(GlobalSnowThicknessId,SnowThicknessFactor*maxSnowThickness);
        Shader.SetGlobalFloat(_GlobalSnowCoverageId,_GlobalSnowCoverage);

    }
}
