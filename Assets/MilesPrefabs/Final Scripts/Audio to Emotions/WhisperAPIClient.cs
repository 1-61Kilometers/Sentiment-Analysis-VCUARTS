using UnityEngine;
using UnityEngine.Networking;
using System.Threading.Tasks;
using System.Collections.Generic;

public class WhisperAPIClient : MonoBehaviour
{
    private const string WHISPER_API_URL = "https://api.openai.com/v1/audio/transcriptions";

    public async Task<string> SendAudioToWhisperAsync(byte[] audioData, string apiKey)
    {
        Debug.Log("Sending audio to Whisper API");
        var formData = new List<IMultipartFormSection>
        {
            new MultipartFormDataSection("model", "whisper-1"),
            new MultipartFormFileSection("file", audioData, "audio.wav", "audio/wav")
        };

        using UnityWebRequest request = UnityWebRequest.Post(WHISPER_API_URL, formData);
        request.SetRequestHeader("Authorization", $"Bearer {apiKey}");

        var operation = request.SendWebRequest();

        while (!operation.isDone)
            await Task.Yield();

        if (request.result == UnityWebRequest.Result.Success)
        {
            var response = JsonUtility.FromJson<WhisperResponse>(request.downloadHandler.text);
            Debug.Log($"Whisper API response: {response.text}");
            return response.text;
        }
        else
        {
            Debug.LogError($"Whisper API Error: {request.error}\nResponse Code: {request.responseCode}\nResponse: {request.downloadHandler.text}");
            return null;
        }
    }

    [System.Serializable]
    private class WhisperResponse
    {
        public string text;
    }
}