using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Group : MonoBehaviour
{
    [SerializeField]  Piece[] pieces;
    
    private bool isActive = false;
    
    private float t;
    private float progress;

    private float duration;

    [SerializeField] private GameObject floor;

    public void Initialize(Vector3 triggerPosition,float duration)
    {
        
        float roadLength = floor.GetComponent<BoxCollider>().size.z;
        this.duration = duration;
        
        
        foreach (var piece in pieces)
        {
            piece.Initialize(roadLength,triggerPosition);
        }
        
    }

     void Update()
     {
         if (!isActive || progress >= 1f) return;


         t += Time.deltaTime;
         progress = Mathf.SmoothStep(0f,1f,t / duration);
         
         
        foreach (Piece p in pieces)
        {
            p.SetPosition(progress);
        }
    }

    public void Trigger()
    {
       isActive = true;
    }
}
