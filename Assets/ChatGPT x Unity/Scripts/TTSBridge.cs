using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Meta.WitAi.TTS.Utilities;
using System.Diagnostics;

public class TTSBridge : MonoBehaviour
{
    [Header("Elements")]
    [SerializeField] private TTSSpeaker speaker;

    // Start is called before the first frame update
    void Start()
    {
        DiscussionBubble.onVoiceButtonClicked += Speak;
        //DiscussionManager.onChatGPTMessageReceived += Speak;
    }

    private void OnDestroy()
    {
        DiscussionBubble.onVoiceButtonClicked -= Speak;
       // DiscussionManager.onChatGPTMessageReceived -= Speak;
    }
    // Update is called once per frame
    void Update()
    {
        
    }

    private void VoiceButtonClickedCallBack(string message)
    {
        if (speaker.IsSpeaking)
        {
            //UnityEngine.Debug.Log("Stopping the speaker");
            speaker.Stop();
        }
        else
        {
            //UnityEngine.Debug.Log("started speaking");
            Speak(message);
        }
    }

    private void Speak(string message)
    {
        string[] messages = message.Split(".");
        speaker.StartCoroutine(speaker.SpeakQueuedAsync(messages));
        //speaker.Speak(message);
    }
}
