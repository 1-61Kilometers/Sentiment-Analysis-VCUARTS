using UnityEngine;

public class Spin : MonoBehaviour
{
    public float rotationSpeed = 90f; // Degrees per second
    private Vector3 centerOffset;

    void Start()
    {
        // Calculate the offset from pivot to center
        Renderer renderer = GetComponent<Renderer>();
        if (renderer != null)
        {
            centerOffset = renderer.bounds.center - transform.position;
        }
        else
        {
            centerOffset = Vector3.zero;
        }
    }

    void Update()
    {
        // Create a rotation quaternion
        Quaternion rotation = Quaternion.Euler(0, 0, rotationSpeed * Time.deltaTime);

        // Move to center, rotate, then move back
        transform.Translate(centerOffset);
        transform.Rotate(Vector3.forward, rotationSpeed * Time.deltaTime);
        transform.Translate(-centerOffset);
    }
}