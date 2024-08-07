using UnityEngine;
using System;

public class EmotionAnalyzer : MonoBehaviour
{
    public EmotionTracker emotionTracker;

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
    }

    public void UpdateEmotions(string jsonString)
    {
        Debug.Log($"Updating emotions with: {jsonString}");
        jsonString = jsonString.Trim();
        int startIndex = jsonString.IndexOf('{');
        int endIndex = jsonString.LastIndexOf('}');
        if (startIndex != -1 && endIndex != -1)
        {
            jsonString = jsonString.Substring(startIndex, endIndex - startIndex + 1);
        }

        EmotionData emotionData = JsonUtility.FromJson<EmotionData>(jsonString);
        emotionTracker.UpdateEmotions(emotionData);

        Debug.Log($"Emotions updated: {jsonString}");
    }
}