using UnityEngine;

public class ToggleObject : MonoBehaviour
{
    [SerializeField] private STTBridge sttBridge;
    
    public GameObject cube; // visual debugging in headset
   

    private void Start()
    {
        cube.SetActive(false);
        sttBridge.SetActivation(false);
    }
    private void Update()
    {
        //mouse and keyboard
        if (Input.GetMouseButtonDown(0)) // Check if left mouse button is pressed
        {
            cube.SetActive(true);
            StartSpeechToText();
            
        }
        else if (Input.GetMouseButtonUp(0)) // Check if left mouse button is released
        {
            cube.SetActive(false);
            StopSpeechToText();
            
        }

        //controller
        if (OVRInput.GetDown(OVRInput.Button.PrimaryIndexTrigger)) //press the trigger down
        {
            cube.SetActive(true);
            StartSpeechToText();

        } 
        else if (OVRInput.GetUp(OVRInput.Button.PrimaryIndexTrigger)) //release the trigger
        {
            cube.SetActive(false);
            StopSpeechToText();
        }

        //hands
        if (OVRInput.GetDown(OVRInput.Button.One, OVRInput.Controller.Hands)){ //pinch
            cube.SetActive(true);
            StartSpeechToText();
        }
        else if (OVRInput.GetUp(OVRInput.Button.One, OVRInput.Controller.Hands)){ // unpinch
            cube.SetActive(false);
            StopSpeechToText();
        }
    }

    public void StartSpeechToText()
    {
        if (sttBridge != null)
        {
            sttBridge.SetActivation(true);
        }
    }

    public void StopSpeechToText()
    {
        if (sttBridge != null)
        {
            sttBridge.SetActivation(false);
        }
    }
}
