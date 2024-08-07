using UnityEngine;
using UnityEngine.Networking;
using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using System.Linq;

public class MicrophoneRecorder : MonoBehaviour
{
    [SerializeField] private string apiKey = "sk-proj-TrLgDNYpGkFx5j3vIDKST3BlbkFJSvuazX2NtU6CV5xekDa1";
    [SerializeField] private EmotionTracker emotionTracker;

    private const string WHISPER_API_URL = "https://api.openai.com/v1/audio/transcriptions";
    private const string CHATGPT_API_URL = "https://api.openai.com/v1/chat/completions";
    private const int RECORD_DURATION = 10;
    private const int SAMPLE_RATE = 48000;

    [System.Serializable]
    public class MicrophoneSettings
    {
        public string deviceName;
        public AudioClip audioClip;
        public bool isRecording = false;
        public TextMeshProUGUI outputText;
        public float voiceActivationThreshold = 0.01f;
        public float silenceThreshold = 0.005f;
        public float minRecordingDuration = 1f;
        public float maxRecordingDuration = 10f;
        public float lastVoiceDetectedTime;
        public float recordingStartTime;
        public List<AudioClip> recordingSegments = new List<AudioClip>();
        public float currentSegmentStartTime;
    }

    private Queue<string> conversationHistory = new Queue<string>();
    private const int MAX_HISTORY_LENGTH = 5;

    public MicrophoneSettings yetiMicrophone = new MicrophoneSettings();
    public MicrophoneSettings webcamMicrophone = new MicrophoneSettings();

    private void Start()
    {
        string[] microphoneNames = Microphone.devices;
        int microphoneCount = microphoneNames.Length;

        // Print the names of all connected microphones
        for (int i = 0; i < microphoneCount; i++)
        {
            Debug.Log($"Microphone {i + 1}: {microphoneNames[i]}");
        }
        Debug.Log("MicrophoneRecorder Start method called");
        InitializeMicrophones();
        ValidateEmotionTracker();
        StartListening(yetiMicrophone);
        StartListening(webcamMicrophone);
    }

    private void Update()
    {
        ProcessMicrophone(yetiMicrophone);
        ProcessMicrophone(webcamMicrophone);
    }

    private void InitializeMicrophones()
    {
        foreach (string device in Microphone.devices)
        {
            if (device.Contains("High Definition Audio Device"))
            {
                yetiMicrophone.deviceName = device;
                Debug.Log("Yeti microphone found: " + device);
            }
            else if (device.Contains("Realtek(R) Audio"))
            {
                webcamMicrophone.deviceName = device;
                Debug.Log("Webcam microphone found: " + device);
            }
        }

        if (yetiMicrophone.deviceName == null || webcamMicrophone.deviceName == null)
        {
            Debug.LogError("One or both required microphones not found!");
        }
    }

    private void ValidateEmotionTracker()
    {
        if (emotionTracker == null)
        {
            emotionTracker = GetComponent<EmotionTracker>();
            if (emotionTracker == null) Debug.LogError("EmotionTracker component not found!");
        }
    }

    private void StartListening(MicrophoneSettings microphone)
    {
        if (microphone.deviceName != null)
        {
            Debug.Log($"Starting to listen on {microphone.deviceName}");
            microphone.audioClip = Microphone.Start(microphone.deviceName, true, RECORD_DURATION, SAMPLE_RATE);
            if (microphone.audioClip == null)
            {
                Debug.LogError($"Failed to start microphone {microphone.deviceName}");
            }
            else
            {
                Debug.Log($"Successfully started listening on {microphone.deviceName}");
            }
        }
        else
        {
            Debug.LogError($"Cannot start listening: device name is null");
        }
    }

    private void ProcessMicrophone(MicrophoneSettings microphone)
    {
        if (microphone.isRecording)
        {
            CheckForSilence(microphone);
        }
        else
        {
            CheckForVoiceActivation(microphone);
        }
    }

    private void CheckForVoiceActivation(MicrophoneSettings microphone)
    {
        float audioLevel = GetAudioLevel(microphone);
        //Debug.Log($"Audio level for {microphone.deviceName}: {audioLevel}");

        if (audioLevel > microphone.voiceActivationThreshold)
        {
            Debug.Log($"Voice activation threshold exceeded for {microphone.deviceName}. Starting recording.");
            StartRecording(microphone);
        }
    }

    private void CheckForSilence(MicrophoneSettings microphone)
    {
        float audioLevel = GetAudioLevel(microphone);

        if (audioLevel > microphone.silenceThreshold)
        {
            microphone.lastVoiceDetectedTime = Time.time;
        }

        float recordingDuration = Time.time - microphone.recordingStartTime;
        float silenceDuration = Time.time - microphone.lastVoiceDetectedTime;
        float currentSegmentDuration = Time.time - microphone.currentSegmentStartTime;

        if (currentSegmentDuration >= microphone.maxRecordingDuration)
        {
            SaveCurrentSegment(microphone);
            StartNewSegment(microphone);
        }
        else if ((silenceDuration > .5f && recordingDuration > microphone.minRecordingDuration) ||
                 recordingDuration > microphone.maxRecordingDuration * 3) // Allow for up to 3 segments
        {
            Debug.Log($"Stopping recording for {microphone.deviceName}. Total recording duration: {recordingDuration}");
            StopRecording(microphone);
        }
    }

    private void SaveCurrentSegment(MicrophoneSettings microphone)
    {
        Microphone.End(microphone.deviceName);

        if (microphone.audioClip != null)
        {
            float segmentDuration = Time.time - microphone.currentSegmentStartTime;
            int samplesRecorded = (int)(segmentDuration * SAMPLE_RATE);

            AudioClip segmentClip = AudioClip.Create($"Segment_{microphone.recordingSegments.Count}", samplesRecorded, microphone.audioClip.channels, SAMPLE_RATE, false);
            float[] samples = new float[samplesRecorded * microphone.audioClip.channels];
            microphone.audioClip.GetData(samples, 0);
            segmentClip.SetData(samples, 0);

            microphone.recordingSegments.Add(segmentClip);
            Debug.Log($"Saved segment {microphone.recordingSegments.Count} for {microphone.deviceName} with {samplesRecorded} samples");
        }
    }

    private float GetAudioLevel(MicrophoneSettings microphone)
    {
        if (microphone.audioClip == null)
        {
            Debug.LogError($"AudioClip is null for {microphone.deviceName}");
            return 0f;
        }

        float[] samples = new float[128];
        int startPosition = Microphone.GetPosition(microphone.deviceName) - 128 + 1;
        if (startPosition < 0) startPosition = 0;

        microphone.audioClip.GetData(samples, startPosition);

        float sum = 0f;
        for (int i = 0; i < samples.Length; i++)
        {
            sum += Mathf.Abs(samples[i]);
        }
        return sum / samples.Length;
    }

    private void StartRecording(MicrophoneSettings microphone)
    {
        if (!microphone.isRecording)
        {
            Debug.Log($"Starting recording on {microphone.deviceName}");
            microphone.isRecording = true;
            microphone.recordingStartTime = Time.time;
            microphone.lastVoiceDetectedTime = Time.time;
            microphone.currentSegmentStartTime = Time.time;

            // Clear previous recording segments
            microphone.recordingSegments.Clear();

            StartNewSegment(microphone);
        }
    }

    private void StartNewSegment(MicrophoneSettings microphone)
    {
        Microphone.End(microphone.deviceName);
        microphone.audioClip = Microphone.Start(microphone.deviceName, false, (int)microphone.maxRecordingDuration, SAMPLE_RATE);
        microphone.currentSegmentStartTime = Time.time;
    }

    private AudioClip CombineAudioClips(List<AudioClip> clips)
    {
        if (clips == null || clips.Count == 0)
            return null;

        int totalSamples = 0;
        foreach (AudioClip clip in clips)
        {
            totalSamples += clip.samples;
        }

        AudioClip combinedClip = AudioClip.Create("CombinedClip", totalSamples, clips[0].channels, SAMPLE_RATE, false);
        float[] combinedSamples = new float[totalSamples * clips[0].channels];

        int position = 0;
        foreach (AudioClip clip in clips)
        {
            float[] clipSamples = new float[clip.samples * clip.channels];
            clip.GetData(clipSamples, 0);
            Array.Copy(clipSamples, 0, combinedSamples, position, clipSamples.Length);
            position += clipSamples.Length;
        }

        combinedClip.SetData(combinedSamples, 0);
        return combinedClip;
    }

    private void StopRecording(MicrophoneSettings microphone)
    {
        if (microphone.isRecording)
        {
            Debug.Log($"Stopping recording for {microphone.deviceName}");
            microphone.isRecording = false;

            SaveCurrentSegment(microphone);

            if (microphone.recordingSegments.Count > 0)
            {
                AudioClip combinedClip = CombineAudioClips(microphone.recordingSegments);
                StartCoroutine(ProcessAudioCoroutine(combinedClip, microphone));
            }
            else
            {
                Debug.LogWarning($"No audio data recorded for {microphone.deviceName}");
            }

            StartListening(microphone);
        }
    }

    private IEnumerator ProcessAudioCoroutine(AudioClip recordedClip, MicrophoneSettings microphone)
    {
        Debug.Log($"Processing audio for {microphone.deviceName}");
        
        // Check audio quality before processing
        if (IsAudioQualitySufficient(recordedClip))
        {
            byte[] audioBytes = WavUtility.FromAudioClip(recordedClip);
            yield return StartCoroutine(SendAudioToWhisperCoroutine(audioBytes, microphone));
        }
        else
        {
            Debug.Log($"Audio quality insufficient for {microphone.deviceName}. Skipping Whisper processing.");
            microphone.outputText.text = $"{microphone.deviceName}: Audio quality too low for processing.";
        }
    }

    private bool IsAudioQualitySufficient(AudioClip clip)
    {
        float[] samples = new float[clip.samples];
        clip.GetData(samples, 0);

        float sumOfSquares = 0f;
        for (int i = 0; i < samples.Length; i++)
        {
            sumOfSquares += samples[i] * samples[i];
        }

        float rmsLevel = Mathf.Sqrt(sumOfSquares / samples.Length);
        
        // You may need to adjust this threshold based on your specific use case
        float threshold = 0.01f;

        Debug.Log($"Audio RMS level: {rmsLevel}");

        return rmsLevel > threshold;
    }

    private IEnumerator SendAudioToWhisperCoroutine(byte[] audioData, MicrophoneSettings microphone)
    {
        Debug.Log($"Sending audio to Whisper API for {microphone.deviceName}");
        var formData = new List<IMultipartFormSection>
        {
            new MultipartFormDataSection("model", "whisper-1"),
            new MultipartFormFileSection("file", audioData, "audio.wav", "audio/wav")
        };

        using UnityWebRequest request = UnityWebRequest.Post(WHISPER_API_URL, formData);
        request.SetRequestHeader("Authorization", $"Bearer {apiKey}");
        yield return request.SendWebRequest();

        if (request.result == UnityWebRequest.Result.Success)
        {
            var response = JsonUtility.FromJson<WhisperResponse>(request.downloadHandler.text);
            Debug.Log($"Whisper API response for {microphone.deviceName}: {response.text}");
            microphone.outputText.text = $"{microphone.deviceName}: {response.text}";
            yield return StartCoroutine(SendTextToChatGPTCoroutine(response.text));
        }
        else
        {
            Debug.LogError($"Whisper API Error for {microphone.deviceName}: {request.error}\nResponse Code: {request.responseCode}\nResponse: {request.downloadHandler.text}");
        }
    }

    [Serializable]
    private class Message
    {
        public string role;
        public string content;
    }

    [Serializable]
    private class ChatGPTRequest
    {
        public string model;
        public List<Message> messages;
    }
    
    private IEnumerator SendTextToChatGPTCoroutine(string text)
    {
        Debug.Log("Sending text to ChatGPT API");

        // Add the new text to the conversation history
        conversationHistory.Enqueue(text);
        if (conversationHistory.Count > MAX_HISTORY_LENGTH)
        {
            conversationHistory.Dequeue();
        }

        // Prepare the messages array for the API request
        var messages = new List<Message>
        {
            new Message
            {
                role = "system",
                content = "Analyze the emotional content of the given text. Output a JSON object with integer values from 0 to 10 for each of these emotions: Angry,Anticipation,Sad,Disgust,Fear,Happy,Neutral,Suprise,Lonely. Use 0 if the emotion is not present. Only output the JSON object, nothing else."
            }
        };

        // Add conversation history to the messages
        foreach (string historicalText in conversationHistory)
        {
            messages.Add(new Message
            {
                role = "user",
                content = historicalText
            });
        }

        // Prepare the JSON data for the API request
        var requestData = new ChatGPTRequest
        {
            model = "gpt-4o",
            messages = messages
        };

        string jsonData = JsonUtility.ToJson(requestData);

        using UnityWebRequest request = new UnityWebRequest(CHATGPT_API_URL, "POST");
        byte[] bodyRaw = System.Text.Encoding.UTF8.GetBytes(jsonData);
        request.uploadHandler = new UploadHandlerRaw(bodyRaw);
        request.downloadHandler = new DownloadHandlerBuffer();
        request.SetRequestHeader("Content-Type", "application/json");
        request.SetRequestHeader("Authorization", $"Bearer {apiKey}");

        yield return request.SendWebRequest();

        if (request.result == UnityWebRequest.Result.Success)
        {
            var chatGPTResponse = JsonUtility.FromJson<ChatGPTResponse>(request.downloadHandler.text);
            Debug.Log($"ChatGPT API response: {chatGPTResponse.choices[0].message.content}");
            UpdateEmotions(chatGPTResponse.choices[0].message.content);
        }
        else
        {
            Debug.LogError($"ChatGPT API Error: {request.error}\nResponse Code: {request.responseCode}\nResponse: {request.downloadHandler.text}");
        }
    }

    public float[] GetCurrentAudioSamples(int sampleCount)
    {
        MicrophoneSettings activeMicrophone = yetiMicrophone.isRecording ? yetiMicrophone : webcamMicrophone;

        if (activeMicrophone.audioClip == null)
        {
            Debug.LogError("MicrophoneRecorder: No active audio clip");
            return null;
        }

        if (!Microphone.IsRecording(activeMicrophone.deviceName))
        {
            Debug.LogWarning($"MicrophoneRecorder: Microphone {activeMicrophone.deviceName} is not recording");
            return null;
        }

        float[] samples = new float[sampleCount];
        int position = Microphone.GetPosition(activeMicrophone.deviceName) - (sampleCount + 1);
        if (position < 0) position = 0;
        activeMicrophone.audioClip.GetData(samples, position);

        Debug.Log($"MicrophoneRecorder: Returned {sampleCount} samples. Max: {samples.Max()}, Min: {samples.Min()}");
        return samples;
    }

    private void UpdateEmotions(string jsonString)
    {
        Debug.Log($"Updating emotions with: {jsonString}");
        jsonString = jsonString.Trim();
        int startIndex = jsonString.IndexOf('{');
        int endIndex = jsonString.LastIndexOf('}');
        if (startIndex != -1 && endIndex != -1)
        {
            jsonString = jsonString.Substring(startIndex, endIndex - startIndex + 1);
        }

        var emotionResponse = JsonUtility.FromJson<EmotionData>(jsonString);
        emotionTracker.UpdateEmotions(emotionResponse);

        Debug.Log($"Emotions updated: {jsonString}");
    }

    [Serializable]
    private class WhisperResponse
    {
        public string text;
    }

    [Serializable]
    private class ChatGPTResponse
    {
        public Choice[] choices;

        [Serializable]
        public class Choice
        {
            public Message message;

            [Serializable]
            public class Message
            {
                public string role;
                public string content;
            }
        }
    }
}