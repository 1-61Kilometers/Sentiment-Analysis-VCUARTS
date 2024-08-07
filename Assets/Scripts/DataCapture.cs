using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Linq;
/*
 * This script is for DATA COLLECTION!
 * Display what emotion for the user to make
 * Iterate through 4 emotions twice
 * Send data + emotion string to network manager
 */
public class DataCapture : MonoBehaviour
{
    private int btnCounter; // number of emotions tracked
    private float timer = 10f; // initial timer value in seconds
    private bool capturing = false; //bool to show if we are capturing 
    private int numLoops=0; // number of times we are cycling through 4 emotions
    
    public OVRFaceExpressions faceExpressions; // reference to OVRFaceExpressions
    public TextMeshProUGUI textBox; //reference to text that shows what emotion to make
    public TextMeshProUGUI timerBox; //reference to text to show time remaining
    
    public NetworkManager networkManager;

    private void Start()
    {
        StartCaptureTimer();
        btnCounter = 0;
    }

    void Update() //logic to keep time & which emotion we are tracking & number of cycles of emotions
    {
        if (capturing)
        {
            // Update timer
            timer -= Time.deltaTime;
            timerBox.text = Mathf.Round(timer).ToString();
            

            if (timer <= 0)
            {
                CaptureData(GetEmotionString(btnCounter)); // send data with emotion string
                btnCounter++;
                
                if (btnCounter == 4) //this creates a loop
                {
                    //after 2 iterations -> break
                    if (!(numLoops == 2))
                    {
                        btnCounter = 0;
                        numLoops++;
                    }
                }
                
                StartCaptureTimer(); 
            }
        }

        
        
    }

    void StartCaptureTimer()
    {
        capturing = true;
        timer = 10f; // Set the timer duration for each emotion
        timerBox.text = Mathf.Round(timer).ToString();
        UpdateInstruction();
    }

    void UpdateInstruction() //function that changes the textBox text to direct the user
    {
        switch (btnCounter)
        {
            case 0:
                textBox.text = "Display this emotion: Happy";
                break;

            case 1:
                textBox.text = "Display this emotion: Sad";
                break;
            case 2:
                textBox.text = "Display this emotion: Mad";
                break;
            case 3:
                textBox.text = "Display this emotion: Anxious";
                break;

            default:
                textBox.text = "Capture complete. Thank you!";
                capturing = false;
                break;
        }
    }

    string GetEmotionString(int index) //function that returns which emotion corresponds to each emotion
    {
     
        switch (index)
        {
            case 0: return "Happy"; //0 -> Happy
            case 1: return "Sad"; //1 -> Sad
            case 2: return "Mad"; //2 -> Mad
            case 3: return "Anxious"; //3 -> Anxious
            default:  return "Unknown"; //4 -> reset
        }
    }

    void CaptureData(string emotion) 
    {
        /*//Debug.Log("sending current emotion to network manager from datacapture.cs: " + emotion);
        float[] floatArray = faceExpressions.ToArray();//get the OVRFaceExpression's Function ToArray() to get float array
        List<string> stringList = floatArray.Select(f => f.ToString()).ToList();//convert float array to a list
        stringList.Add(emotion);// Adding emotion
        string[] stringArray = stringList.ToArray();// Convert the list back to an array to send off to our networkManager
        networkManager.SendDataToServer(stringArray);//sending facial expression array from the toarray function using networkManager.cs*/
    }
}
