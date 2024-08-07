using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using UnityEngine.UI;
using System;
using Random = UnityEngine.Random;
using OpenAI;
using OpenAI.Chat;
using System.Diagnostics;
using Newtonsoft.Json.Linq;

public class DiscussionManager : MonoBehaviour
{
    public NetworkManager networkManager;

    [Header("Elements")]


    [Header("Events")]
    public static Action onMessageRecieved;
    public static Action<string> onChatGPTMessageReceived;

    [Header("Authentication")]
    [SerializeField] private string apiKey;
    [SerializeField] private string organizationId;
    private OpenAIClient api;

    [Header("Settings")]
    [SerializeField] private List<ChatPrompt> chatPrompts = new List<ChatPrompt>();

    void Start()
    {
        Authenticate();
        Initilize();
    }

    private void Authenticate()
    {
        api = new OpenAIClient(new OpenAIAuthentication(apiKey, organizationId));
    }


    private void Initilize()
    {
        ChatPrompt prompts = new ChatPrompt("system", "You will be taking in a statement and will tell me if the statement is Happy, Sad, Mad, or Scared. Also give a metric out of 10 for each emotion. Only show the emotion and the metrics. Show all emotion levels and metrics for each emotions, please. Do not give a response in any other format than the one provided");

        chatPrompts.Add(prompts);

    }

    public async void AskButtonCallback(string message)
    {

        ChatPrompt prompt = new ChatPrompt("user", message);
        chatPrompts.Add(prompt);


        ChatRequest request = new ChatRequest(
             messages: chatPrompts,
             model: OpenAI.Models.Model.GPT3_5_Turbo, temperature: 0.2);

        try
        {
            var result = await api.ChatEndpoint.GetCompletionAsync(request);

            // Parsing the JSON response to extract emotion metrics using Newtonsoft.Json
            var jsonResponse = result.ToString();
            JObject jsonObject = JObject.Parse(jsonResponse);
            var content = jsonObject["choices"][0]["message"]["content"];

            ChatPrompt chatResult = new ChatPrompt("system", result.FirstChoice.ToString());
            chatPrompts.Add(chatResult);

            onChatGPTMessageReceived?.Invoke(result.FirstChoice.ToString());

            networkManager.SendVoiceEmotionToServer(content.ToString());

        }
        catch (Exception e)
        {
            UnityEngine.Debug.Log(e);
        }

    }
}
