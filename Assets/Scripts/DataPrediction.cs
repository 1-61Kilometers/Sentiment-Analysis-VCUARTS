using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Linq;

/*
 * This script is to predict emotions every 3 second of user
 * Currenty, the NetworkManager script takes care of storing all the data in an array and displaying
 */

public class DataPrediction : MonoBehaviour
{
    [Tooltip("Represents the duration of a loop in seconds.")]
    [SerializeField] int loopSecond = 3;


    [Tooltip("Reference to the networkManager script")]
    public NetworkManager networkManager;

    [Tooltip("reference to OVRFaceExpressions script on the player")]
    public OVRFaceExpressions faceExpressions;

    private float timer = 0.0f;
    

    void Update()
    {
        // Increment the timer by the time passed since the last frame
        timer += Time.deltaTime;

        // Check if the timer has reached the interval
        if (timer >= loopSecond)
        {
            if (faceExpressions.FaceTrackingEnabled)
            {
                // Call the PredictData() function
                PredictData();
            }
            else
            {
                Debug.Log("trying to predict but facial tracking is not available");
            }
            

            // Reset the timer
            timer = 0.0f;
        }
    }


    //function for prediction only
    void PredictData()
    {
        //accessing all 52 points of facial data and converting to a string array.
        //todo:change this to just sending the data as a float array here :).
        float[] floatArray = faceExpressions.ToArray();
        string[] stringArray = new string[floatArray.Length];

        //chaning float array to string array
        for (int i = 0; i < floatArray.Length; i++)
        {
            stringArray[i] = floatArray[i].ToString();
        }
        //send array to network manager for predicition
        networkManager.GetPredicitionFromServer(stringArray);
    }
}
