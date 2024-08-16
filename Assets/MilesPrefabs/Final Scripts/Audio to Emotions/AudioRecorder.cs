using UnityEngine;
using System.Collections;
using System.Linq;
using System.Collections.Generic;

public class AudioRecorder : MonoBehaviour
{
    [SerializeField] private int recordingLength = 10;
    [SerializeField] private int sampleRate = 44100;

    private AudioClip microphoneClip;
    private AudioClip preRecordedClip;
    private string microphoneName;
    private bool usePreRecordedAudio = false;
    private AudioSource audioSource;
    private bool isPlaying = false;
    private float playbackStartTime;

    public bool IsUsingPreRecordedAudio()
    {
        return usePreRecordedAudio;
    }

    private void Awake()
    {
        audioSource = gameObject.AddComponent<AudioSource>();
    }

    public List<string> GetAvailableMicrophones()
    {
        return Microphone.devices.ToList();
    }

    public void SetMicrophone(string microphoneName)
    {
        if (Microphone.devices.Contains(microphoneName))
        {
            this.microphoneName = microphoneName;
            usePreRecordedAudio = false;
            Debug.Log($"Set microphone to: {this.microphoneName}");
        }
        else
        {
            Debug.LogError($"Microphone {microphoneName} not found.");
        }
    }

    public void UsePreRecordedAudio(AudioClip clip)
    {
        preRecordedClip = clip;
        usePreRecordedAudio = true;
        Debug.Log("Set to use pre-recorded audio");
    }

    public string GetMicrophoneName()
    {
        return microphoneName;
    }

    public void StartRecording()
    {
        StopAllCoroutines();
        audioSource.Stop();
        
        if (usePreRecordedAudio)
        {
            if (preRecordedClip == null)
            {
                Debug.LogError("No pre-recorded audio clip assigned.");
                return;
            }
            audioSource.clip = preRecordedClip;
            audioSource.loop = false;
            audioSource.Play();
            isPlaying = true;
            playbackStartTime = Time.time;
            Debug.Log("Started playback of pre-recorded audio");
        }
        else
        {
            if (string.IsNullOrEmpty(microphoneName))
            {
                Debug.LogError("No microphone selected. Please select a microphone before recording.");
                return;
            }
            if (Microphone.IsRecording(microphoneName))
            {
                Microphone.End(microphoneName);
            }
            microphoneClip = Microphone.Start(microphoneName, true, recordingLength, sampleRate);
            audioSource.clip = microphoneClip;
            audioSource.loop = true;
            audioSource.Play();
            isPlaying = true;
            playbackStartTime = Time.time;
            Debug.Log($"Started recording on {microphoneName}");
        }

        StartCoroutine(MonitorPlayback());
    }

    private IEnumerator MonitorPlayback()
    {
        while (isPlaying)
        {
            if (usePreRecordedAudio && !audioSource.isPlaying)
            {
                isPlaying = false;
                Debug.Log("Pre-recorded audio playback completed");
            }
            yield return null;
        }
    }

    public void StopRecording()
    {
        isPlaying = false;
        StopAllCoroutines();
        audioSource.Stop();
        
        if (!usePreRecordedAudio && !string.IsNullOrEmpty(microphoneName))
        {
            Microphone.End(microphoneName);
            Debug.Log($"Stopped recording on {microphoneName}");
        }
        else
        {
            Debug.Log("Stopped playback of pre-recorded audio");
        }
    }

    public AudioClip GetRecordedClip()
    {
        return usePreRecordedAudio ? preRecordedClip : microphoneClip;
    }

    public int GetPosition()
    {
        if (!isPlaying)
        {
            return 0;
        }

        if (usePreRecordedAudio)
        {
            return Mathf.FloorToInt(audioSource.time * preRecordedClip.frequency);
        }
        else
        {
            return Microphone.GetPosition(microphoneName);
        }
    }

    public bool IsFinished()
    {
        if (!isPlaying)
        {
            return true;
        }

        if (usePreRecordedAudio)
        {
            return !audioSource.isPlaying;
        }
        else
        {
            return false; // Microphone recording doesn't finish unless stopped manually
        }
    }
}