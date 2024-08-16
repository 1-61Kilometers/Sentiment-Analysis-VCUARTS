using UnityEngine;
using System.Collections;

public class AudioSourceRecorder : MonoBehaviour
{
    [SerializeField] private AudioSource _audioSource;
    [SerializeField] private int recordingLength = 10;
    [SerializeField] private int sampleRate = 44100;

    private AudioClip _recordedClip;
    private bool _isRecording = false;
    private float _recordStartTime;

    public AudioSource AudioSource
    {
        get { return _audioSource; }
        set { _audioSource = value; }
    }

    private void Start()
    {
        if (_audioSource == null)
        {
            _audioSource = GetComponent<AudioSource>();
            if (_audioSource == null)
            {
                Debug.LogError("AudioSource not found. Please assign an AudioSource to this component.");
            }
        }
    }

    public void StartRecording()
    {
        if (_audioSource == null || _audioSource.clip == null)
        {
            Debug.LogError("AudioSource or AudioClip not set. Cannot start recording.");
            return;
        }

        _recordedClip = AudioClip.Create("RecordedClip", recordingLength * sampleRate, _audioSource.clip.channels, sampleRate, false);
        _isRecording = true;
        _recordStartTime = Time.time;
        _audioSource.Play();
        StartCoroutine(RecordAudio());
    }

    public void StopRecording()
    {
        _isRecording = false;
        _audioSource.Stop();
    }

    public AudioClip GetRecordedClip()
    {
        return _recordedClip;
    }

    public int GetPosition()
    {
        if (_isRecording)
        {
            float elapsedTime = Time.time - _recordStartTime;
            return Mathf.FloorToInt(elapsedTime * sampleRate);
        }
        return 0;
    }

    private IEnumerator RecordAudio()
    {
        float[] samples = new float[sampleRate * _audioSource.clip.channels];
        int writePosition = 0;

        while (_isRecording && writePosition < _recordedClip.samples)
        {
            int samplesAvailable = _audioSource.timeSamples - writePosition;
            if (samplesAvailable > 0)
            {
                if (samplesAvailable > samples.Length)
                    samplesAvailable = samples.Length;

                _audioSource.clip.GetData(samples, _audioSource.timeSamples - samplesAvailable);
                _recordedClip.SetData(samples, writePosition);
                writePosition += samplesAvailable;
            }
            yield return null;
        }
    }
}