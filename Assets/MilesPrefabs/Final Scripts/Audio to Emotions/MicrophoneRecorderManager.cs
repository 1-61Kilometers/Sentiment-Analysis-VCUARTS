using UnityEngine;
using System.Collections;
using System.Threading.Tasks;
using TMPro;
using System.Linq;
using System.Diagnostics;
using UnityEngine.UI;
using System.Collections.Generic;

public class MicrophoneRecorderManager : MonoBehaviour
{
    public string apiKey = "sk-proj-TrLgDNYpGkFx5j3vIDKST3BlbkFJSvuazX2NtU6CV5xekDa1";
    public TextMeshProUGUI outputTextUser1;
    public TextMeshProUGUI outputTextUser2;
    public TextMeshProUGUI timingTextUser1;
    public TextMeshProUGUI timingTextUser2;
    public TextMeshProUGUI companyNameTextUser1;
    public TextMeshProUGUI companyNameTextUser2;
    public bool showDebugInfo = true;
    public float audioQualityThreshold = 0.01f;

    public TMP_Dropdown dropdownUser1;
    public TMP_Dropdown dropdownUser2;

    private AudioRecorder audioRecorderUser1;
    private AudioRecorder audioRecorderUser2;
    private AudioProcessor audioProcessorUser1;
    private AudioProcessor audioProcessorUser2;
    private WhisperAPIClient whisperAPIClient;
    private ChatGPTAPIClient chatGPTAPIClient;
    private EmotionAnalyzer emotionAnalyzerUser1;
    private EmotionAnalyzer emotionAnalyzerUser2;

    private Stopwatch stopwatchUser1 = new Stopwatch();
    private Stopwatch stopwatchUser2 = new Stopwatch();

    private void Start()
    {
        InitializeComponents();
        PopulateMicrophoneDropdowns();
    }

    private void InitializeComponents()
    {
        audioRecorderUser1 = gameObject.AddComponent<AudioRecorder>();
        audioRecorderUser2 = gameObject.AddComponent<AudioRecorder>();
        audioProcessorUser1 = gameObject.AddComponent<AudioProcessor>();
        audioProcessorUser2 = gameObject.AddComponent<AudioProcessor>();
        whisperAPIClient = gameObject.AddComponent<WhisperAPIClient>();
        chatGPTAPIClient = gameObject.AddComponent<ChatGPTAPIClient>();
        emotionAnalyzerUser1 = gameObject.AddComponent<EmotionAnalyzer>();
        emotionAnalyzerUser2 = gameObject.AddComponent<EmotionAnalyzer>();
    }

    private void PopulateMicrophoneDropdowns()
    {
        var microphones = Microphone.devices.ToList();
        
        PopulateDropdown(dropdownUser1, microphones, true);
        PopulateDropdown(dropdownUser2, microphones, false);
    }

    private void PopulateDropdown(TMP_Dropdown dropdown, List<string> options, bool isUser1)
    {
        dropdown.ClearOptions();
        dropdown.AddOptions(options);
        dropdown.onValueChanged.AddListener(delegate { OnMicrophoneSelected(dropdown, isUser1); });
    }

    public void SetMicrophone(string microphoneName, bool isUser1)
    {
        AudioRecorder audioRecorder = isUser1 ? audioRecorderUser1 : audioRecorderUser2;

        if (audioRecorder != null)
        {
            audioRecorder.SetMicrophone(microphoneName);
            
            // If both microphones are selected, start the recording process
            if (audioRecorderUser1 != null && audioRecorderUser2 != null &&
                !string.IsNullOrEmpty(audioRecorderUser1.GetMicrophoneName()) && 
                !string.IsNullOrEmpty(audioRecorderUser2.GetMicrophoneName()))
            {
                StartCoroutine(ContinuousRecordingCoroutineUser1());
                StartCoroutine(ContinuousRecordingCoroutineUser2());
            }
        }
        else
        {
            UnityEngine.Debug.LogError($"AudioRecorder for User {(isUser1 ? "1" : "2")} is null.");
        }
    }

    private void OnMicrophoneSelected(TMP_Dropdown dropdown, bool isUser1)
    {
        string selectedMicrophone = dropdown.options[dropdown.value].text;
        SetMicrophone(selectedMicrophone, isUser1);
    }

    private void OnGUI()
    {
        if (showDebugInfo)
        {
            GUI.Label(new Rect(10, 10, 300, 20), $"User 1 Volume: {audioProcessorUser1.CurrentVolume:F4}");
            GUI.Label(new Rect(10, 30, 300, 20), $"User 1 Recording: {audioProcessorUser1.IsRecording}");
            GUI.Label(new Rect(10, 50, 300, 20), $"User 2 Volume: {audioProcessorUser2.CurrentVolume:F4}");
            GUI.Label(new Rect(10, 70, 300, 20), $"User 2 Recording: {audioProcessorUser2.IsRecording}");
        }
    }

    private IEnumerator ContinuousRecordingCoroutineUser1()
    {
        while (true)
        {
            yield return StartCoroutine(RecordAudioSegment(audioRecorderUser1, audioProcessorUser1));
            ProcessLatestRecording(audioRecorderUser1, audioProcessorUser1, outputTextUser1, stopwatchUser1, timingTextUser1, emotionAnalyzerUser1, companyNameTextUser2);
            yield return new WaitForSeconds(0.1f);
        }
    }

    private IEnumerator ContinuousRecordingCoroutineUser2()
    {
        while (true)
        {
            yield return StartCoroutine(RecordAudioSegment(audioRecorderUser2, audioProcessorUser2));
            ProcessLatestRecording(audioRecorderUser2, audioProcessorUser2, outputTextUser2, stopwatchUser2, timingTextUser2, emotionAnalyzerUser2, companyNameTextUser1);
            yield return new WaitForSeconds(0.1f);
        }
    }

    private IEnumerator RecordAudioSegment(AudioRecorder recorder, AudioProcessor processor)
    {
        recorder.StartRecording();
        
        while (!processor.IsRecording)
        {
            processor.ProcessAudioData(recorder.GetRecordedClip(), recorder.GetPosition());
            yield return null;
        }

        while (processor.IsRecording)
        {
            processor.ProcessAudioData(recorder.GetRecordedClip(), recorder.GetPosition());
            yield return null;
        }

        recorder.StopRecording();
    }

    private void ProcessLatestRecording(AudioRecorder recorder, AudioProcessor processor, TextMeshProUGUI outputText, Stopwatch stopwatch, TextMeshProUGUI timingText, EmotionAnalyzer emotionAnalyzer, TextMeshProUGUI adSuggestionText)
    {
        AudioClip processedClip = processor.GetProcessedClip(recorder.GetRecordedClip().frequency);

        if (IsAudioQualitySufficient(processedClip))
        {
            UnityEngine.Debug.Log("Audio quality sufficient. Processing audio...");
            stopwatch.Restart();
            _ = ProcessAudioAsync(processedClip, outputText, stopwatch, timingText, emotionAnalyzer, adSuggestionText);
        }
        else
        {
            UnityEngine.Debug.Log("Audio quality insufficient. Skipping processing.");
            outputText.text = "Audio quality too low for processing.";
        }
    }

    private async Task ProcessAudioAsync(AudioClip processedClip, TextMeshProUGUI outputText, Stopwatch stopwatch, TextMeshProUGUI timingText, EmotionAnalyzer emotionAnalyzer, TextMeshProUGUI companyNameText)
    {
        byte[] audioBytes = WavUtility.FromAudioClip(processedClip);
        
        Stopwatch whisperStopwatch = Stopwatch.StartNew();
        string transcribedText = await whisperAPIClient.SendAudioToWhisperAsync(audioBytes, apiKey);
        whisperStopwatch.Stop();

        if (!string.IsNullOrEmpty(transcribedText))
        {
            await UpdateUIAsync(() => outputText.text = transcribedText);
            
            Stopwatch chatGPTStopwatch = Stopwatch.StartNew();
            var (emotionJson, companyName) = await chatGPTAPIClient.SendTextToChatGPTAsync(transcribedText, apiKey);
            chatGPTStopwatch.Stop();

            if (!string.IsNullOrEmpty(emotionJson))
            {
                await UpdateUIAsync(() => emotionAnalyzer.UpdateEmotions(emotionJson));
            }

            if (!string.IsNullOrEmpty(companyName))
            {
                await UpdateUIAsync(() => companyNameText.text = $"Suggested Company: {companyName}");
            }

            stopwatch.Stop();

            string timingInfo = $"Total processing time: {stopwatch.ElapsedMilliseconds}ms\n" +
                                $"Whisper API: {whisperStopwatch.ElapsedMilliseconds}ms\n" +
                                $"ChatGPT API: {chatGPTStopwatch.ElapsedMilliseconds}ms";

            UnityEngine.Debug.Log(timingInfo);
            await UpdateUIAsync(() => timingText.text = timingInfo);
        }
    }

    private async Task UpdateUIAsync(System.Action action)
    {
        await Task.Yield();
        action.Invoke();
    }

    private bool IsAudioQualitySufficient(AudioClip clip)
    {
        float[] samples = new float[clip.samples];
        clip.GetData(samples, 0);

        float maxAbsValue = samples.Max(Mathf.Abs);
        float rmsLevel = Mathf.Sqrt(samples.Select(s => s * s).Average());
        
        UnityEngine.Debug.Log($"Audio max absolute value: {maxAbsValue}, RMS level: {rmsLevel}");

        if (maxAbsValue < audioQualityThreshold)
        {
            UnityEngine.Debug.Log($"Max absolute value {maxAbsValue} is below threshold {audioQualityThreshold}");
            return false;
        }

        if (rmsLevel < audioQualityThreshold)
        {
            UnityEngine.Debug.Log($"RMS level {rmsLevel} is below threshold {audioQualityThreshold}");
            return false;
        }

        return true;
    }
}