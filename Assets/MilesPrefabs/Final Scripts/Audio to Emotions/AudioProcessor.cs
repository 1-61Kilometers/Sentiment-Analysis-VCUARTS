using UnityEngine;
using System;
using System.Linq;
using System.Collections.Generic;

public class AudioProcessor : MonoBehaviour
{
    [SerializeField] private float detectionThreshold = 0.05f;
    [SerializeField] private float silenceThreshold = 0.04f;
    [SerializeField] private float silenceDuration = 1f;

    private List<float> _samplesBuffer = new List<float>();
    private bool _isRecording;
    private float _lastSoundTime;
    private int _lastReadPosition;
    private float _currentVolume;

    public bool IsRecording => _isRecording;
    public float CurrentVolume => _currentVolume;

    public void ProcessAudioData(AudioClip clip, int currentPosition)
    {
        if (currentPosition < _lastReadPosition)
        {
            _lastReadPosition = 0; // Reset if we've looped
        }

        if (currentPosition <= _lastReadPosition) return;

        int samplesToRead = currentPosition - _lastReadPosition;
        float[] samples = new float[samplesToRead];

        if (!TryGetAudioData(clip, samples)) return;

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
            }
        }
    }

    private bool TryGetAudioData(AudioClip clip, float[] samples)
    {
        try
        {
            clip.GetData(samples, _lastReadPosition);
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
        Debug.Log("Started recording");
    }

    private void StopRecording()
    {
        _isRecording = false;
        Debug.Log("Stopped recording");
    }

    public AudioClip GetProcessedClip(int sampleRate)
    {
        AudioClip processedClip = AudioClip.Create("ProcessedClip", _samplesBuffer.Count, 1, sampleRate, false);
        processedClip.SetData(_samplesBuffer.ToArray(), 0);
        return processedClip;
    }
}