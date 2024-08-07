using UnityEngine;
using System;
using UnityEngine.UI;
using TMPro;

public class smileDetection : MonoBehaviour
{
    // Reference to the OVRFaceExpressions component
    public OVRFaceExpressions faceExpressions;

    // Set the update interval in seconds
    //public float updateInterval = 0.5f; // for example, update every 0.5 seconds

    //private float timeSinceLastUpdate = 0f;

    public TextMeshProUGUI textBox; // Reference to the TextMeshPro UI object

    void Update()
    {
        if (faceExpressions.ValidExpressions)
        {
            // Get the smile expression weights
            float lipCornerPullerL = faceExpressions[OVRFaceExpressions.FaceExpression.LipCornerPullerL];
            float lipCornerPullerR = faceExpressions[OVRFaceExpressions.FaceExpression.LipCornerPullerR];

            // Get the frown expression weights
            float lipCornerDepressorL = faceExpressions[OVRFaceExpressions.FaceExpression.LipCornerDepressorL];
            float lipCornerDepressorR = faceExpressions[OVRFaceExpressions.FaceExpression.LipCornerDepressorR];

            // Set the TextMeshPro text with expression values
            textBox.text = $"Smile:\nLipCornerPullerL: {lipCornerPullerL}\nLipCornerPullerR: {lipCornerPullerR}\n\nFrown:\nLipCornerDepressorL: {lipCornerDepressorL}\nLipCornerDepressorR: {lipCornerDepressorR}";
        } else
        {
            textBox.text = "facial expressions are not valid at this time";
        }
         
    }
    
}
