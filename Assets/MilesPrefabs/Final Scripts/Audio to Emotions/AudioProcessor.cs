using UnityEngine;
using System;
using System.Linq;
using System.Collections.Generic;

public class AudioProcessor : MonoBehaviour
{
    [SerializeField] private float detectionThreshold = 0.02f;
    [SerializeField] private float silenceThreshold = 0.01f;
    [SerializeField] private float silenceDuration = 1f;

    private List<float> _samplesBuffer = new List<float>();
    private bool _isRecording;
    private float _lastSoundTime;
    private int _lastReadPosition;
    private float _currentVolume;
    private int _totalSamplesProcessed;

    public bool IsRecording => _isRecording;
    public float CurrentVolume => _currentVolume;

    public void ProcessAudioData(AudioClip clip, int currentPosition)
    {
        int clipLength = clip.samples;
        
        if (currentPosition < _lastReadPosition)
        {
            // We've looped, so process remaining samples from last position to end
            int remainingSamples = clipLength - _lastReadPosition;
            if (remainingSamples > 0)
            {
                float[] remainingData = new float[remainingSamples];
                if (TryGetAudioData(clip, remainingData, _lastReadPosition, remainingSamples))
                {
                    ProcessSamples(remainingData);
                }
            }
            _lastReadPosition = 0;
        }

        int samplesToRead = currentPosition - _lastReadPosition;
        if (samplesToRead <= 0) return;

        float[] samples = new float[samplesToRead];

        if (!TryGetAudioData(clip, samples, _lastReadPosition, samplesToRead)) return;

        _lastReadPosition = currentPosition;
        _totalSamplesProcessed += samplesToRead;

        ProcessSamples(samples);

        // Check if we've processed the entire clip
        if (_totalSamplesProcessed >= clipLength)
        {
            Debug.Log("Finished processing entire clip");
            _totalSamplesProcessed = 0;
            if (_isRecording)
            {
                StopRecording();
            }
        }
    }

    private void ProcessSamples(float[] samples)
    {
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

    private bool TryGetAudioData(AudioClip clip, float[] samples, int startSample, int sampleCount)
    {
        try
        {
            clip.GetData(samples, startSample);
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