using UnityEngine;
using UnityEngine.Networking;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;

[Serializable]
public struct EmotionData
{
    public int Suprise;
    public int Happy;
    public int Sad;
    public int Angry;
    public int Fear;
    public int Disgust;
    public int Anticipation;
    public int Lonely;
}

[Serializable]
public class EmotionParticleSystem
{
    public string emotion;
    public ParticleSystem lowIntensityParticleSystem;
    public ParticleSystem mediumIntensityParticleSystem;
    public ParticleSystem highIntensityParticleSystem;
}

public class EmotionTracker : MonoBehaviour
{
    [SerializeField] private EmotionData emotionData;
    [SerializeField] public string MainEmotion { get; private set; } = "Neutral";
    [SerializeField] private TextMeshProUGUI werms;
    [SerializeField] private List<EmotionParticleSystem> emotionParticleSystems;
    public event Action OnEmotionsUpdated;

    private void Start()
    {
        // Ensure all particle systems are initially stopped
        foreach (var eps in emotionParticleSystems)
        {
            eps.lowIntensityParticleSystem?.Stop();
            eps.mediumIntensityParticleSystem?.Stop();
            eps.highIntensityParticleSystem?.Stop();
        }
    }

    public void UpdateEmotions(EmotionData newData)
    {
        emotionData = newData;
        UpdateMainEmotion();
        OnEmotionsUpdated?.Invoke();
        UpdateUIAndParticles();
    }

    private void UpdateMainEmotion()
    {
        int maxValue = Mathf.Max(
            emotionData.Angry,
            emotionData.Anticipation,
            emotionData.Disgust,
            emotionData.Sad,
            emotionData.Fear,
            emotionData.Happy,
            emotionData.Suprise,
            emotionData.Lonely
        );

        MainEmotion = maxValue switch
        {
            0 => "Neutral",
            _ when maxValue == emotionData.Angry => "Angry",
            _ when maxValue == emotionData.Anticipation => "Anticipation",
            _ when maxValue == emotionData.Disgust => "Disgust",
            _ when maxValue == emotionData.Sad => "Sad",
            _ when maxValue == emotionData.Fear => "Fear",
            _ when maxValue == emotionData.Happy => "Happy",
            _ when maxValue == emotionData.Suprise => "Suprise",
            _ when maxValue == emotionData.Lonely => "Lonely",
            _ => "Unknown"
        };

        Debug.Log($"Main emotion updated: {MainEmotion} (Intensity: {maxValue})");
    }

    private void UpdateUIAndParticles()
    {
        if (werms != null)
        {
            werms.text = MainEmotion == "Anticipation" ? "Anxiety" : MainEmotion;
        }
        UpdateParticleSystems();
    }

    private void UpdateParticleSystems()
    {
        int intensity = GetEmotionIntensity(MainEmotion);

        foreach (var eps in emotionParticleSystems)
        {
            if (eps.emotion == MainEmotion)
            {
                PlayAppropriateParticleSystem(eps, intensity);
            }
            else
            {
                StopAllParticleSystems(eps);
            }
        }
    }

    private int GetEmotionIntensity(string emotion)
    {
        return emotion switch
        {
            "Angry" => emotionData.Angry,
            "Anticipation" => emotionData.Anticipation,
            "Disgust" => emotionData.Disgust,
            "Sad" => emotionData.Sad,
            "Fear" => emotionData.Fear,
            "Happy" => emotionData.Happy,
            "Suprise" => emotionData.Suprise,
            "Lonely" => emotionData.Lonely,
            _ => 0
        };
    }

    private void PlayAppropriateParticleSystem(EmotionParticleSystem eps, int intensity)
    {
        StopAllParticleSystems(eps);

        if (intensity >= 7 && eps.highIntensityParticleSystem != null)
        {
            eps.highIntensityParticleSystem.Play();
        }
        else if (intensity >= 4 && eps.mediumIntensityParticleSystem != null)
        {
            eps.mediumIntensityParticleSystem.Play();
        }
        else if (intensity > 0 && eps.lowIntensityParticleSystem != null)
        {
            eps.lowIntensityParticleSystem.Play();
        }
    }

    private void StopAllParticleSystems(EmotionParticleSystem eps)
    {
        eps.lowIntensityParticleSystem?.Stop();
        eps.mediumIntensityParticleSystem?.Stop();
        eps.highIntensityParticleSystem?.Stop();
    }
}