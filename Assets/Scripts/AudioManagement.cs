using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AudioManagement : MonoBehaviour
{
    [SerializeField] private EmotionTracker emotionTracker;

    [Tooltip("Ambience")]
    [SerializeField] private AudioSource backgroundSource; //0

    [Tooltip("Environment")]
    [SerializeField] private AudioSource environmentSource; //1

    [Tooltip("Angry")]
    [SerializeField] private AudioSource angrySource; //2

    [Tooltip("Anxious")]
    [SerializeField] private AudioSource anxiousSource; //3

    [Tooltip("Determination")]
    [SerializeField] private AudioSource determinationSource; //4

    [Tooltip("Happy")]
    [SerializeField] private AudioSource happySource; //5

    [Tooltip("Sad")]
    [SerializeField] private AudioSource sadSource; //6

    [Tooltip("Neutral")]
    [SerializeField] private AudioSource neutralSource; //7

    [Tooltip("Lonely")]
    [SerializeField] private AudioSource lonelySource; //8

    [Tooltip("Suprise")]
    [SerializeField] private AudioSource supriseSource; //9

    [Tooltip("Disgust")]
    [SerializeField] private AudioSource disgustSource; //10

    [Tooltip("Number of Emotions Playing at a Time")]
    [SerializeField] private int emotionWindowSize = 2;

    [Tooltip("Starting volume for all audio sources")]
    [SerializeField] private float startingVolume = 0.068f;

    private AudioSource[] audioSources;
    private List<AudioSource> emotionWindow;

    private string mainEmotion;
    private string prevEmotion;

    private void Start()
    {
        audioSources = new AudioSource[]
        {
            backgroundSource, environmentSource, angrySource, anxiousSource,
            determinationSource, happySource, sadSource, neutralSource,
            lonelySource, supriseSource, disgustSource
        };

        emotionWindow = new List<AudioSource>();

        // Set the starting volume and stop all audio sources
        foreach (var source in audioSources)
        {
            if (source != null)
            {
                source.volume = startingVolume;
                source.Stop();
            }
        }

        // Start background and environment audio
        if (backgroundSource != null && backgroundSource.clip != null)
        {
            backgroundSource.Play();
        }
        if (environmentSource != null && environmentSource.clip != null)
        {
            environmentSource.Play();
        }
    }

    private void Update()
    {
        if (emotionTracker != null)
        {
            prevEmotion = emotionTracker.MainEmotion;

            if (mainEmotion != prevEmotion) // If the main emotion has changed
            {
                UpdateAudioBasedOnEmotion(prevEmotion);
                mainEmotion = prevEmotion; // Update the main emotion
            }
        }
    }

    public void UpdateAudioBasedOnEmotion(string emotion)
    {
        // Find the audio source for the new emotion
        AudioSource newSource = GetAudioSourceForEmotion(emotion);
        
        // If the new source is not already in the emotion window
        if (newSource != null && newSource.clip !=null && !emotionWindow.Contains(newSource))
        {
            if (emotionWindow.Count >= emotionWindowSize)
            {
                // Fade out the oldest emotion and remove it from the list
                if (emotionWindow[0] != null)
                {
                    StartCoroutine(FadeOutAudio(emotionWindow[0]));
                    
                }
                emotionWindow.RemoveAt(0);
            }

            // Add the new emotion source and fade it in
            emotionWindow.Add(newSource);
            Debug.Log("adding: " + newSource);
            StartCoroutine(FadeInAudio(newSource));
        }
    }

    private AudioSource GetAudioSourceForEmotion(string emotion)
    {
        switch (emotion)
        {
            case "Angry":
                return angrySource;
            case "Fear":
                return anxiousSource;
            case "Anticipation":
                return determinationSource;
            case "Happy":
                return happySource;
            case "Sad":
                return sadSource;
            case "Neutral":
                return neutralSource;
            case "Lonely":
                return lonelySource;
            case "Suprise":
                return supriseSource;
            case "Disgust":
                return disgustSource;
            default:
                return null; // No match found
        }
    }

    private IEnumerator FadeOutAudio(AudioSource audioSource, float fadeDuration = 1.0f)
    {
        if (audioSource != null && audioSource.clip != null)
        {
            float startVolume = audioSource.volume;

            while (audioSource.volume > 0)
            {
                audioSource.volume -= startVolume * Time.deltaTime / fadeDuration;
                yield return null;
            }

            audioSource.Stop();
            audioSource.volume = startingVolume; // Reset to starting volume
        }
    }

    private IEnumerator FadeInAudio(AudioSource audioSource, float fadeDuration = 1.0f)
    {
        if (audioSource != null && audioSource.clip != null)
        {
            audioSource.volume = 0f;
            audioSource.Play();

            while (audioSource.volume < startingVolume)
            {
                audioSource.volume += startingVolume * Time.deltaTime / fadeDuration;
                yield return null;
            }

            audioSource.volume = startingVolume; // Ensure it's exactly at the starting volume
        }
    }
}
