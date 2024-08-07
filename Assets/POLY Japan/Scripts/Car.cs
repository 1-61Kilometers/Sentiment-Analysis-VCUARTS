using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Car : MonoBehaviour
{
    //todo -> be able to change a car to a cop car
    [SerializeField] private float _speed = 5f;
    private MeshRenderer _meshRenderer;
    private Quaternion _rotation;

    private void Start()
    {
        _rotation = transform.rotation;
        _meshRenderer = GetComponent<MeshRenderer>();
    }
    private void Update()
    { 
        //translate cars based off which way they're facing
        Vector3 newPosition = transform.position;
        if(_rotation.y > 0) // pos
        {
            newPosition.z += -_speed * Time.deltaTime;
        } else
        {
            newPosition.z += _speed * Time.deltaTime;
        }
        
        transform.position = newPosition;
    }
    public void ToggleCarMesh(bool isVisible)
    {
        
        _meshRenderer.enabled = isVisible;
        
    }

    public void SetCarSpeed(float speed)
    {
        _speed = speed;
    }
    public float GetCarSpeed()
    {
        return _speed;
    }
}
