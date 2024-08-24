using UnityEngine;

public class ToggleCursorVisibility : MonoBehaviour
{
    private bool isCursorVisible = true;

    void Update()
    {
        // Check if the P key is pressed
        if (Input.GetKeyDown(KeyCode.P))
        {
            ToggleCursor();
        }
    }

    private void ToggleCursor()
    {
        // Toggle the cursor visibility
        isCursorVisible = !isCursorVisible;
        Cursor.visible = isCursorVisible;

        // Optionally lock the cursor when hidden (if needed)
        Cursor.lockState = isCursorVisible ? CursorLockMode.None : CursorLockMode.Locked;
    }
}
