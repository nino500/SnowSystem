using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class Trigger: MonoBehaviour
{

    [SerializeField] private Group[] groups;

    [SerializeField] private float triggerDistance = 1.0f;

    [SerializeField] private float duration = 1.0f;
    
    
    private HashSet<Group> triggeredGroups = new HashSet<Group>();

    private Transform player = null;
    

    void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player"))
        {
            player = other.transform;
            
        }
    }

    private void Awake()
    {
        foreach (Group group in groups)
        {
            group.Initialize(transform.position,duration);
        }
    }


    private void Update()
    {
        if (!player)
        {
            return;
        }


        foreach (Group group in groups)
        {
            if (group ==null|| triggeredGroups.Contains(group))
            {
                continue;
            }
            
            Vector3 groupToPlayer = player.position - group.transform.position;
            groupToPlayer.y = 0f;

            if (groupToPlayer.magnitude < triggerDistance)
            {
                group.Trigger();
                triggeredGroups.Add(group);
            }


        }
        
        
    }
}
