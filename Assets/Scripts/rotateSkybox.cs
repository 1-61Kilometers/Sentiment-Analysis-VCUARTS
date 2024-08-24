using UnityEngine;

public class rotateSkybox : MonoBehaviour
{
    public float rotationSpeed = 1.0f; // Speed of rotation in degrees per second

    private Material skyboxMaterial;
    private float currentRotation;

    void Start()
    {
        // Get the current skybox material
        skyboxMaterial = RenderSettings.skybox;

        if (skyboxMaterial == null)
        {
            Debug.LogError("No skybox material found. Please assign a skybox material in RenderSettings.");
            this.enabled = false;
            return;
        }

        // Ensure the material is of the correct shader type
        if (!skyboxMaterial.shader.name.Equals("Skybox/Cubemap"))
        {
            Debug.LogError("The skybox material must use the Skybox/Cubemap shader.");
            this.enabled = false;
            return;
        }

        // Initialize the current rotation value
        currentRotation = skyboxMaterial.GetFloat("_Rotation");
    }

    void Update()
    {
        if (skyboxMaterial == null)
        {
            return;
        }

        // Update the rotation value
        currentRotation += rotationSpeed * Time.deltaTime;
        currentRotation = currentRotation % 360.0f; // Keep the rotation value within 0-360 degrees

        // Apply the rotation to the skybox material
        skyboxMaterial.SetFloat("_Rotation", currentRotation);
    }
}
