using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;
using Random = UnityEngine.Random;

public class Piece : MonoBehaviour
{
    
    
    
    private float progress;

    private Vector3 startPosition;
    private Vector3 assembledPosition;
    private Quaternion startRotation;
    private Quaternion assembledRotation;


    private float roadLength;
    
    
    public void Initialize(float length,Vector3 triggerPosition)
    {
        
        roadLength = length;
        
        Vector3 distance = triggerPosition - transform.position;
        distance.y = 0f;
        
        float u = distance.magnitude / length;


        float radius = 3f;
        
        float x = radius*Mathf.Cos(2f*Mathf.PI*u);
        float y = radius*Mathf.Sin(2f*Mathf.PI*u);
        float z = u*length;
        Vector3 startBase = new Vector3(x, y, z);
        
        
        float side = Random.value<0.5f? -1.0f : 1.0f;
        float sideways = side*Random.Range(1.5f,3.0f);
        
        float height = Random.Range(-0.3f, 0.3f);
        
        float forward = Random.Range(-0.8f,0.8f );
        
        Vector3 offset = new Vector3(sideways, height, forward);
        
        
        
        
        assembledPosition = transform.localPosition;
        assembledRotation = transform.localRotation;
        
        startPosition = startBase + offset;
        startRotation = assembledRotation*Random.rotationUniform;
        
        
        
        SetPosition(0);
        
    }

    
    
    
    
    public void SetPosition(float progress)
    {
        Vector3 position = Vector3.Lerp(startPosition, assembledPosition, progress);
        Quaternion rotation = Quaternion.Lerp(startRotation, assembledRotation, progress);

        transform.localPosition = position;
        transform.localRotation = rotation;

    }
}
