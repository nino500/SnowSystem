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
    
    [Header("覆雪参数")]
    public float _GlobalSnowThickness = 0.5f;//全局雪厚度

    
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
        
        
        int snowWorldAreaId = Shader.PropertyToID("_SnowWorldArea");
        int topDownHeightRangeId = Shader.PropertyToID("_TopDownHeightRange");
        int GlobalSnowThicknessId = Shader.PropertyToID("_GlobalSnowThickness");
        int _TopDownHeightRTId = Shader.PropertyToID("_TopDownHeightRT");
        
        
        Shader.SetGlobalVector(snowWorldAreaId,_SnowWorldArea);
        Shader.SetGlobalVector(topDownHeightRangeId,_TopDownHeightRange);
        Shader.SetGlobalFloat(GlobalSnowThicknessId,_GlobalSnowThickness);
        Shader.SetGlobalTexture(_TopDownHeightRTId,heightRT);
    }
}
