using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class followonfeet : MonoBehaviour
{
    public Transform camera;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        this.transform.position = new Vector3(Camera.main.transform.position.x, 0, Camera.main.transform.position.z);
    }
}
