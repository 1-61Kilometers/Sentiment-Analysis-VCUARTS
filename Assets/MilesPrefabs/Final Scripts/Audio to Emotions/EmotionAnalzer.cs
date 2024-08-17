using UnityEngine;
using System;
using UnityEngine.UI.Extensions;

public class EmotionAnalyzer : MonoBehaviour
{
    public EmotionTracker emotionTracker;
    public RadarPolygon radarPolygon;

    private void Start()
    {
        if (emotionTracker == null)
        {
            emotionTracker = GetComponent<EmotionTracker>();
            if (emotionTracker == null)
            {
                Debug.LogError("EmotionTracker not found. Please assign it in the inspector or ensure it's on the same GameObject.");
                enabled = false;
                return;
            }
        }

        if (radarPolygon == null)
        {
            GameObject radarPolygonObject = GameObject.Find("RadarPolygonData");
            radarPolygon = radarPolygonObject.GetComponent<RadarPolygon>(); // how do you get the radar polygon?
            if (radarPolygon == null)
            {
                Debug.LogError("RadarPolygon not found. Please assign it in the inspector or ensure it's on the same GameObject.");
                enabled = false;
                return;
            }
        }
    }

    public void UpdateEmotions(string jsonString)
    {
        jsonString = jsonString.Trim();
        int startIndex = jsonString.IndexOf('{');
        int endIndex = jsonString.LastIndexOf('}');
        if (startIndex != -1 && endIndex != -1)
        {
            jsonString = jsonString.Substring(startIndex, endIndex - startIndex + 1);
        }

        EmotionData emotionData = JsonUtility.FromJson<EmotionData>(jsonString);
        emotionTracker.UpdateEmotions(emotionData);
        Debug.Log("UPDATING");
        UpdateRadarPolygon(emotionData);
    }

    private void UpdateRadarPolygon(EmotionData emotionData)
    {
        float[] convertedValues = new float[]
        {
            ConvertToFloat(emotionData.Happy),
            ConvertToFloat(emotionData.Sad),
            ConvertToFloat(emotionData.Angry),
            ConvertToFloat(emotionData.Fear),
            ConvertToFloat(emotionData.Disgust),
            ConvertToFloat(emotionData.Anticipation),
            ConvertToFloat(emotionData.Lonely),
            ConvertToFloat(emotionData.Suprise)
        };
        radarPolygon.value = convertedValues;
        radarPolygon.segment = convertedValues.Length;
        radarPolygon.SetVerticesDirty();
    }

    private float ConvertToFloat(int value)
    {
        float convertedValue = Mathf.Clamp01(value / 10f);
        if(convertedValue < .2){
            convertedValue = .2f;
        }
        return convertedValue;
    }
}