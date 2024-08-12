using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AudioManagementTest : MonoBehaviour
{
    private int currentEmotionIndex = 0;
    [SerializeField] private AudioManagement audioManagement;
    private string [] sources = new string[]
        {
        "Happy", "Sad", "Lonely", "Angry", "Anticipation", "Fear", "Suprise"};
void Start()
    {
        InvokeRepeating("SendEmotionToManager", 2.0f, 5f);
    }

    private void SendEmotionToManager()
    {
        if (audioManagement != null)
        {
            string currentEmotion = sources[currentEmotionIndex];
            audioManagement.UpdateAudioBasedOnEmotion(currentEmotion);

            currentEmotionIndex = (currentEmotionIndex + 1) % sources.Length;
        }
    }
}
