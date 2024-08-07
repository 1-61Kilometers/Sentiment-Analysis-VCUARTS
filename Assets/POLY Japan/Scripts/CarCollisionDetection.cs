using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CarCollisionDetection : MonoBehaviour
{
    private Transform teleportTarget;

    private void Start()
    {
        
        teleportTarget = transform.GetChild(0); // Assuming the teleport target is the first child

        if (teleportTarget == null)
        {
            Debug.LogError("Teleport target not found!");
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Car") && teleportTarget != null)
        {
            Vector3 newPosition = other.transform.position;
            newPosition.z = teleportTarget.position.z;
            other.transform.position = newPosition;
        }
    }
}
