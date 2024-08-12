using UnityEngine;
using UnityEngine.Events;

public class ContinuousLocomotion : MonoBehaviour
{
    public float moveSpeed = 1.0f;
    public OVRCameraRig cameraRig;
    public OVRInput.Controller controllerType = OVRInput.Controller.RTouch; // Use right controller by default

    // Events for button presses
    public UnityEvent onAButtonPressed;
    public UnityEvent onBButtonPressed;

    private Transform rigParent;
    private bool wasAPressed = false;
    private bool wasBPressed = false;

    private void Start()
    {
        if (cameraRig == null)
        {
            Debug.LogError("OVRCameraRig reference is not set in the Inspector!");
            return;
        }

        // Get the parent of the OVRCameraRig to move
        rigParent = cameraRig.transform.parent;
        if (rigParent == null)
        {
            Debug.LogWarning("OVRCameraRig doesn't have a parent. Creating one.");
            GameObject parent = new GameObject("CameraRigParent");
            parent.transform.position = cameraRig.transform.position;
            cameraRig.transform.SetParent(parent.transform);
            rigParent = parent.transform;
        }

        Debug.Log("ContinuousLocomotion script initialized");
    }

    private void Update()
    {
        HandleMovement();
        HandleButtonEvents();
    }

    private void HandleMovement()
    {
        // Get joystick input
        Vector2 joystickInput = OVRInput.Get(OVRInput.Axis2D.PrimaryThumbstick, controllerType);
        
        if (cameraRig == null || rigParent == null)
        {
            Debug.LogError("CameraRig or rigParent is null!");
            return;
        }

        // Get the camera's forward and right vectors
        Vector3 cameraForward = cameraRig.centerEyeAnchor.forward;
        Vector3 cameraRight = cameraRig.centerEyeAnchor.right;

        // Project the camera's forward and right vectors onto the horizontal plane
        cameraForward.y = 0;
        cameraRight.y = 0;
        cameraForward.Normalize();
        cameraRight.Normalize();

        // Calculate movement direction based on camera orientation
        Vector3 moveDirection = cameraRight * joystickInput.x + cameraForward * joystickInput.y;

        // Apply movement to the parent object
        Vector3 movement = moveDirection * moveSpeed * Time.deltaTime;
        rigParent.position += movement;
    }

    private void HandleButtonEvents()
    {
        // Check for A button press
        bool isAPressed = OVRInput.Get(OVRInput.Button.One, controllerType);
        if (isAPressed && !wasAPressed)
        {
            onAButtonPressed.Invoke();
            Debug.Log("A button pressed");
        }
        wasAPressed = isAPressed;

        // Check for B button press
        bool isBPressed = OVRInput.Get(OVRInput.Button.Two, controllerType);
        if (isBPressed && !wasBPressed)
        {
            onBButtonPressed.Invoke();
            Debug.Log("B button pressed");
        }
        wasBPressed = isBPressed;
    }
}