using UnityEngine;
using System.Linq;

public class AudioRecorder : MonoBehaviour
{
    [SerializeField] private int recordingLength = 10;
    [SerializeField] private int sampleRate = 44100;

    private AudioClip _microphoneClip;
    private string _microphoneName;

    public bool TryFindHighDefinitionAudioDevice(bool useFirstDevice)
    {
        var hdDevices = Microphone.devices
            .Where(device => device.ToLower().Contains("high definition audio device"))
            .ToList();

        if (hdDevices.Count >= 2)
        {
            _microphoneName = useFirstDevice ? hdDevices[0] : hdDevices[1];
            Debug.Log($"Assigned High Definition Audio Device: {_microphoneName}");
            return true;
        }
        else if (hdDevices.Count == 1)
        {
            _microphoneName = hdDevices[0];
            Debug.Log($"Only one High Definition Audio Device found: {_microphoneName}");
            return true;
        }

        Debug.LogWarning("No High Definition Audio Device found. Available microphones:");
        foreach (var device in Microphone.devices)
        {
            Debug.Log(device);
        }

        return false;
    }

    public void StartRecording()
    {
        if (Microphone.IsRecording(_microphoneName))
        {
            Microphone.End(_microphoneName);
        }
        _microphoneClip = Microphone.Start(_microphoneName, true, recordingLength, sampleRate);
        Debug.Log($"Started recording on {_microphoneName}");
    }

    public void StopRecording()
    {
        Microphone.End(_microphoneName);
        Debug.Log($"Stopped recording on {_microphoneName}");
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