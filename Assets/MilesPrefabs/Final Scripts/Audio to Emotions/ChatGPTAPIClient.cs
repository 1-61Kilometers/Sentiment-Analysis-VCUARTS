using UnityEngine;
using UnityEngine.Networking;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Text.RegularExpressions;

public class ChatGPTAPIClient : MonoBehaviour
{
    private const string CHATGPT_API_URL = "https://api.openai.com/v1/chat/completions";

    public bool enableAdSuggestions = true;  // Public boolean to toggle ad suggestions

    public async Task<(string emotionAnalysis, string companyName)> SendTextToChatGPTAsync(string text, string apiKey)
    {
        //Debug.Log("Sending text to ChatGPT API");

        string systemPrompt = enableAdSuggestions
            ? "Analyze the emotional content of the given text and suggest an appropriate real world company name if nothing good output N/A. Output a JSON object with two properties: 'emotions' and 'companyName'. The 'emotions' property should contain integer values from 0 to 10 for each of these emotions: Angry, Hope, Sad, Disgust, Anxiety, Happy, Neutral, Surprise, Lonely. Use 0 if the emotion is not present. The 'companyName' property should ONLY contain the name of a company that would be appropriate based on the emotional analysis, with no additional text or explanation. Only output the JSON object, nothing else."
            : "Analyze the emotional content of the given text. Output a JSON object with one property: 'emotions'. The 'emotions' property should contain integer values from 0 to 10 for each of these emotions: Angry, Hope, Sad, Disgust, Anxiety, Happy, Neutral, Surprise, Lonely. Use 0 if the emotion is not present. Only output the JSON object, nothing else.";

        var messages = new List<Message>
        {
            new Message
            {
                role = "system",
                content = systemPrompt
            },
            new Message
            {
                role = "user",
                content = text
            }
        };

        var requestData = new ChatGPTRequest
        {
            model = "gpt-4o-mini",
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
            string processedContent = ProcessResponse(chatGPTResponse.choices[0].message.content);
            var (emotionAnalysis, companyName) = ParseProcessedResponse(processedContent);
            //Debug.Log($"Processed ChatGPT API response - Emotions: {emotionAnalysis}, Company Name: {companyName}");
            return (emotionAnalysis, companyName);
        }
        else
        {
            Debug.LogError($"ChatGPT API Error: {request.error}\nResponse Code: {request.responseCode}\nResponse: {request.downloadHandler.text}");
            return (null, null);
        }
    }

    private string ProcessResponse(string response)
    {
        string processedResponse = response;
        processedResponse = Regex.Replace(processedResponse, "\"Anxiety\"\\s*:", "\"Fear\":");
        processedResponse = Regex.Replace(processedResponse, "\"Hope\"\\s*:", "\"Anticipation\":");
        return processedResponse;
    }

    private (string emotionAnalysis, string companyName) ParseProcessedResponse(string processedResponse)
    {
        // Parse the JSON response
        var jsonResponse = JsonUtility.FromJson<APIResponse>(processedResponse);

        // Convert the emotions object to a string
        string emotionAnalysis = JsonUtility.ToJson(jsonResponse.emotions);

        return (emotionAnalysis, jsonResponse.companyName);
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

    [System.Serializable]
    private class APIResponse
    {
        public Emotions emotions;
        public string companyName;
    }

    [System.Serializable]
    private class Emotions
    {
        public int Angry;
        public int Anticipation;
        public int Sad;
        public int Disgust;
        public int Fear;
        public int Happy;
        public int Neutral;
        public int Surprise;
        public int Lonely;
    }
}