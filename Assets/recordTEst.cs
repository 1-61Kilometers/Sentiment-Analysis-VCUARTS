using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

/// <summary>
/// Handles recording audio from a Blue Snowball microphone, detecting sound levels,
/// and playing back the recorded audio. Supports multiple recordings.
/// </summary>
public class recordTEst : MonoBehaviour
{
    [Header("Audio Detection Settings")]
    [SerializeField] private float detectionThreshold = 0.01f;
    [SerializeField] private float silenceThreshold = 0.005f;
    [SerializeField] private float silenceDuration = 1f;

    [Header("Microphone Settings")]
    [SerializeField] private int recordingLength = 10;
    [SerializeField] private int sampleRate = 44100;

    [Header("Debug")]
    [SerializeField] private bool showDebugInfo = true;

    private AudioClip _microphoneClip;
    private AudioClip _recordedClip;
    private List<float> _samplesBuffer = new List<float>();
    private bool _isRecording;
    private float _lastSoundTime;
    private string _microphoneName;
    private int _lastReadPosition;
    private float _currentVolume;
    private bool _isListening = true;

    private const string MicrophoneBrand = "blue";
    private const string MicrophoneModel = "snowball";

    private void Start()
    {
        if (!TryFindMicrophone())
        {
            Debug.LogError("Blue Snowball microphone not found. Please check the connection and try again.");
            enabled = false;
            return;
        }

        StartCoroutine(RecordAndDetectSound());
    }

    private void OnGUI()
    {
        if (showDebugInfo)
        {
            GUI.Label(new Rect(10, 10, 300, 20), $"Current Volume: {_currentVolume:F4}");
            GUI.Label(new Rect(10, 30, 300, 20), $"Is Recording: {_isRecording}");
            GUI.Label(new Rect(10, 50, 300, 20), $"Samples Buffer Size: {_samplesBuffer.Count}");
            GUI.Label(new Rect(10, 70, 300, 20), $"Is Listening: {_isListening}");
        }
    }

    private bool TryFindMicrophone()
    {
        _microphoneName = Microphone.devices.FirstOrDefault(device => 
            device.ToLower().Contains(MicrophoneBrand) && device.ToLower().Contains(MicrophoneModel));

        if (!string.IsNullOrEmpty(_microphoneName))
        {
            Debug.Log($"Found Blue Snowball microphone: {_microphoneName}");
            return true;
        }

        Debug.LogWarning("Blue Snowball microphone not found. Available microphones:");
        foreach (var device in Microphone.devices)
        {
            Debug.Log(device);
        }

        return false;
    }

    private IEnumerator RecordAndDetectSound()
    {
        while (true)
        {
            ResetMicrophone();
            yield return StartCoroutine(ListenForSound());

            while (_isRecording)
            {
                ProcessAudioData();
                yield return null;
            }

            yield return new WaitForSeconds(1f); // Wait a bit before listening again
        }
    }

    private IEnumerator ListenForSound()
    {
        _isListening = true;
        while (_isListening)
        {
            ProcessAudioData();
            if (_isRecording)
            {
                _isListening = false;
            }
            yield return null;
        }
    }

    private void ResetMicrophone()
    {
        if (Microphone.IsRecording(_microphoneName))
        {
            Microphone.End(_microphoneName);
        }
        _microphoneClip = Microphone.Start(_microphoneName, true, recordingLength, sampleRate);
        _lastReadPosition = 0;
        Debug.Log("Microphone reset and started");
    }

    private void ProcessAudioData()
    {
        int currentPosition = Microphone.GetPosition(_microphoneName);
        if (currentPosition < _lastReadPosition)
        {
            _lastReadPosition = 0; // Reset if we've looped
        }

        if (currentPosition <= _lastReadPosition) return;

        int samplesToRead = currentPosition - _lastReadPosition;
        float[] samples = new float[samplesToRead];

        if (!TryGetAudioData(samples)) return;

        _lastReadPosition = currentPosition;

        _currentVolume = CalculateAverageVolume(samples);

        if (!_isRecording && _currentVolume > detectionThreshold)
        {
            StartRecording();
        }
        
        if (_isRecording)
        {
            _samplesBuffer.AddRange(samples);

            if (_currentVolume > silenceThreshold)
            {
                _lastSoundTime = Time.time;
            }
            else if (Time.time - _lastSoundTime > silenceDuration)
            {
                StopRecording();
                PlaybackRecording();
            }
        }
    }

    private bool TryGetAudioData(float[] samples)
    {
        try
        {
            _microphoneClip.GetData(samples, _lastReadPosition);
            return true;
        }
        catch (Exception e)
        {
            Debug.LogError($"Error reading microphone data: {e.Message}");
            return false;
        }
    }

    private float CalculateAverageVolume(float[] samples)
    {
        return samples.Select(Math.Abs).Average();
    }

    private void StartRecording()
    {
        _isRecording = true;
        _samplesBuffer.Clear();
        Debug.Log("Started recording with Blue Snowball");
    }

    private void StopRecording()
    {
        _isRecording = false;
        Microphone.End(_microphoneName);

        _recordedClip = AudioClip.Create("RecordedClip", _samplesBuffer.Count, 1, sampleRate, false);
        _recordedClip.SetData(_samplesBuffer.ToArray(), 0);

        Debug.Log("Stopped recording");
    }

    private void PlaybackRecording()
    {
        if (_recordedClip == null) return;

        AudioSource audioSource = gameObject.AddComponent<AudioSource>();
        audioSource.clip = _recordedClip;
        audioSource.Play();
        Debug.Log("Playing back recording");
    }
}