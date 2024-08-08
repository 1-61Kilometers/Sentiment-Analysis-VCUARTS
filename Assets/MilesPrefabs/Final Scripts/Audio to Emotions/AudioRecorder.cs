using UnityEngine;
using System.Linq;
using System.Collections.Generic;

public class AudioRecorder : MonoBehaviour
{
    [SerializeField] private int recordingLength = 10;
    [SerializeField] private int sampleRate = 44100;

    private AudioClip _microphoneClip;
    private string _microphoneName;

    public List<string> GetAvailableMicrophones()
    {
        return Microphone.devices.ToList();
    }

    public void SetMicrophone(string microphoneName)
    {
        if (Microphone.devices.Contains(microphoneName))
        {
            _microphoneName = microphoneName;
            Debug.Log($"Set microphone to: {_microphoneName}");
        }
        else
        {
            Debug.LogError($"Microphone {microphoneName} not found.");
        }
    }

    public string GetMicrophoneName()
    {
        return _microphoneName;
    }

    public void StartRecording()
    {
        if (string.IsNullOrEmpty(_microphoneName))
        {
            Debug.LogError("No microphone selected. Please select a microphone before recording.");
            return;
        }

        if (Microphone.IsRecording(_microphoneName))
        {
            Microphone.End(_microphoneName);
        }
        _microphoneClip = Microphone.Start(_microphoneName, true, recordingLength, sampleRate);
        Debug.Log($"Started recording on {_microphoneName}");
    }

    public void StopRecording()
    {
        if (!string.IsNullOrEmpty(_microphoneName))
        {
            Microphone.End(_microphoneName);
            Debug.Log($"Stopped recording on {_microphoneName}");
        }
    }

    public AudioClip GetRecordedClip()
    {
        return _microphoneClip;
    }

    public int GetPosition()
    {
        return Microphone.GetPosition(_microphoneName);
    }
}