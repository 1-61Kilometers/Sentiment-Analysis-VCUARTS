using UnityEngine;
using System.Collections.Generic;
using UnityEngine.UI;
using TMPro;

/*
 * Custom enum class of expressions in OVRFaceExpressions FaceExpressions enum class that we actually want to track
 * Add more expressions as needed
 */
public enum CustomFaceExpression
{
    //Smiling data 
    LipCornerPullerL,
    LipCornerPullerR,

    LipCornerDepressorL,
    LipCornerDepressorR,
    
}
public class emotionDetection : MonoBehaviour
{
    //reference to OVRFaceExpressions
    public OVRFaceExpressions faceExpressions;

    //reference to debug text window
    public TextMeshProUGUI textBox; // Reference to the TextMeshPro UI object

    //private for expressions that enter within the threshold
    private List<CustomFaceExpression> expressionsInThreshold = new List<CustomFaceExpression>();


    public class FacialExpressionData
    {
        //Expressions dictionary for the key-value pair of the expressions and their weight.
        public Dictionary<CustomFaceExpression, float> Expressions = new Dictionary<CustomFaceExpression, float>();


        /* AddExpression(expression, value)
         * takes in a facial expression in the enum class of expressions in OVRFaceExpressions
         * If the expression isn't in the dictionary -> adds it.
         * If it is in the dictionary -> replaces float value
         */
        public void AddExpression(CustomFaceExpression expression, float value)
        {
            if (!Expressions.ContainsKey(expression))
            {
                Expressions.Add(expression, value);
            }
            else
            {
                Expressions[expression] = value;
            }
        }

        /*IsExpressionCloseToValue(expression,targetValue,threshold
         * takes in an expression and evaluates it to see if it is within the range
         * returns a boolean
         */
        public bool IsExpressionCloseToValue(CustomFaceExpression expression, float targetValue, float threshold = 0.2f)
        {
            if (Expressions.ContainsKey(expression))
            {
                float value = Expressions[expression];
                return Mathf.Abs(value - targetValue) <= threshold;
            }
            return false;
        }
    }

    /* AnaylzeFacialExpressions()
     * main function within the update function
     * assign values to each face expression
     * 
     */
    public void AnalyzeFacialExpressions()
    {
        FacialExpressionData currentExpressions = new FacialExpressionData();

        if (faceExpressions.ValidExpressions)
        {
            // Obtain actual expressions from the OVRFaceExpressions component
            float lipCornerPullerL = faceExpressions[OVRFaceExpressions.FaceExpression.LipCornerPullerL];
            float lipCornerPullerR = faceExpressions[OVRFaceExpressions.FaceExpression.LipCornerPullerR];
            float lipCornerDepressorL = faceExpressions[OVRFaceExpressions.FaceExpression.LipCornerDepressorL];
            float lipCornerDepressorR = faceExpressions[OVRFaceExpressions.FaceExpression.LipCornerDepressorR];

            // Add expressions to the currentExpressions object
            currentExpressions.AddExpression(CustomFaceExpression.LipCornerPullerL, lipCornerPullerL);
            currentExpressions.AddExpression(CustomFaceExpression.LipCornerPullerR, lipCornerPullerR);
            currentExpressions.AddExpression(CustomFaceExpression.LipCornerDepressorL, lipCornerDepressorL);
            currentExpressions.AddExpression(CustomFaceExpression.LipCornerDepressorR, lipCornerDepressorR);

            // Check if expressions enter the threshold and call HandleExpressionsInThreshold if they do
            if (currentExpressions.IsExpressionCloseToValue(CustomFaceExpression.LipCornerPullerL, 0.8f))
            {
                HandleExpressionsInThreshold(CustomFaceExpression.LipCornerPullerL);
            }
            if (currentExpressions.IsExpressionCloseToValue(CustomFaceExpression.LipCornerPullerR, 0.8f))
            {
                HandleExpressionsInThreshold(CustomFaceExpression.LipCornerPullerR);
            }
            if (currentExpressions.IsExpressionCloseToValue(CustomFaceExpression.LipCornerDepressorL, 0.8f))
            {
                HandleExpressionsInThreshold(CustomFaceExpression.LipCornerDepressorL);
            }
            if (currentExpressions.IsExpressionCloseToValue(CustomFaceExpression.LipCornerDepressorR, 0.8f))
            {
                HandleExpressionsInThreshold(CustomFaceExpression.LipCornerDepressorR);
            }
            // Repeat the above process for other expressions as needed
        }
        else
        {
            //Debug.Log("Facial expressions are not valid at this time");
        }
    }



    private void HandleExpressionsInThreshold(CustomFaceExpression expression)
    {
        if (!expressionsInThreshold.Contains(expression))
        {
            expressionsInThreshold.Add(expression);
            //Debug.Log(expression.ToString() + " has entered the threshold");
            // Optionally, update the debug text window with expressionsInThreshold data

            /* stopping text from updating
            UpdateDebugText();
            */
        }
    }
    private void UpdateDebugText()
    {
        /* stopping text from updating
        string debugText = "Expressions in threshold: ";
        foreach (CustomFaceExpression expression in expressionsInThreshold)
        {
            debugText += expression.ToString() + ", ";
        }
        textBox.text = debugText;
        */
    }

    

    void Update()
    {
        AnalyzeFacialExpressions();

        // Clear the expressionsInThreshold list to avoid repetition in the debug output
        expressionsInThreshold.Clear();
    }
}
