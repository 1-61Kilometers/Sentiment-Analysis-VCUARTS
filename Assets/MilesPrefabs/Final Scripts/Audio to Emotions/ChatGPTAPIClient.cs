using UnityEngine;
using UnityEngine.Networking;
using System.Collections.Generic;
using System.Threading.Tasks;

public class ChatGPTAPIClient : MonoBehaviour
{
    private const string CHATGPT_API_URL = "https://api.openai.com/v1/chat/completions";

    public async Task<string> SendTextToChatGPTAsync(string text, string apiKey)
    {
        Debug.Log("Sending text to ChatGPT API");

        var messages = new List<Message>
        {
            new Message
            {
                role = "system",
                content = "Analyze the emotional content of the given text. Output a JSON object with integer values from 0 to 10 for each of these emotions: Angry,Anticipation,Sad,Disgust,Fear,Happy,Neutral,Suprise,Lonely. Use 0 if the emotion is not present. Only output the JSON object, nothing else."
            },
            new Message
            {
                role = "user",
                content = text
            }
        };

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

        var operation = request.SendWebRequest();

        while (!operation.isDone)
            await Task.Yield();

        if (request.result == UnityWebRequest.Result.Success)
        {
            var chatGPTResponse = JsonUtility.FromJson<ChatGPTResponse>(request.downloadHandler.text);
            Debug.Log($"ChatGPT API response: {chatGPTResponse.choices[0].message.content}");
            return chatGPTResponse.choices[0].message.content;
        }
        else
        {
            Debug.LogError($"ChatGPT API Error: {request.error}\nResponse Code: {request.responseCode}\nResponse: {request.downloadHandler.text}");
            return null;
        }
    }

    [System.Serializable]
    private class Message
    {
        public string role;
        public string content;
    }

    [System.Serializable]
    private class ChatGPTRequest
    {
        public string model;
        public List<Message> messages;
    }

    [System.Serializable]
    private class ChatGPTResponse
    {
        public Choice[] choices;

        [System.Serializable]
        public class Choice
        {
            public Message message;
        }
    }
}