using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Meta.WitAi;
using Meta.WitAi.Json;
using Oculus.Voice;
using TMPro;
using static System.Net.Mime.MediaTypeNames;

public class STTBridge : MonoBehaviour
{

    [SerializeField] private DiscussionManager discussionManager;
    [SerializeField] private TextMeshProUGUI _textBox;
    [Header("UI")]
    //[SerializeField] private TMP_InputField promptInputField;

    [Header("Voice")]
    [SerializeField] private AppVoiceExperience appVoiceExperience;

    // Whether voice is activated
    public bool IsActive => _active;

    // here is the output statement that every one will read
    
    private bool _active = false;

    private string recordedMessage = "";

    
    // Add delegates
    private void OnEnable()
    {
        appVoiceExperience.VoiceEvents.OnRequestCreated.AddListener(OnRequestStarted);
        appVoiceExperience.VoiceEvents.OnPartialTranscription.AddListener(OnRequestTranscript);
        appVoiceExperience.VoiceEvents.OnFullTranscription.AddListener(OnRequestTranscript);
        appVoiceExperience.VoiceEvents.OnStartListening.AddListener(OnListenStart);
        appVoiceExperience.VoiceEvents.OnStoppedListening.AddListener(OnListenStop);
        appVoiceExperience.VoiceEvents.OnStoppedListeningDueToDeactivation.AddListener(OnListenForcedStop);
        appVoiceExperience.VoiceEvents.OnStoppedListeningDueToInactivity.AddListener(OnListenForcedStop);
        appVoiceExperience.VoiceEvents.OnResponse.AddListener(OnRequestResponse);
        appVoiceExperience.VoiceEvents.OnError.AddListener(OnRequestError);
    }
    // Remove delegates
    private void OnDisable()
    {
        appVoiceExperience.VoiceEvents.OnRequestCreated.RemoveListener(OnRequestStarted);
        appVoiceExperience.VoiceEvents.OnPartialTranscription.RemoveListener(OnRequestTranscript);
        appVoiceExperience.VoiceEvents.OnFullTranscription.RemoveListener(OnRequestTranscript);
        appVoiceExperience.VoiceEvents.OnStartListening.RemoveListener(OnListenStart);
        appVoiceExperience.VoiceEvents.OnStoppedListening.RemoveListener(OnListenStop);
        appVoiceExperience.VoiceEvents.OnStoppedListeningDueToDeactivation.RemoveListener(OnListenForcedStop);
        appVoiceExperience.VoiceEvents.OnStoppedListeningDueToInactivity.RemoveListener(OnListenForcedStop);
        appVoiceExperience.VoiceEvents.OnResponse.RemoveListener(OnRequestResponse);
        appVoiceExperience.VoiceEvents.OnError.RemoveListener(OnRequestError);
    }

    // Request began
    private void OnRequestStarted(WitRequest r)
    {
        // Begin
        _active = true;
    }
    // Request transcript
    private void OnRequestTranscript(string transcript)
    {
        
        
    }

    // Method to get the recorded message
    public string GetRecordedMessage()
    {
        return recordedMessage;
    }

    private void SetRecordedMessage(string data)
    {
        recordedMessage = data;
        
    }
    // Listen start
    private void OnListenStart()
    {
        
        
    }
    // Listen stop
    private void OnListenStop()
    {
        
    }
    // Listen stop
    private void OnListenForcedStop()
    {
        OnRequestComplete();
    }
    // Request response
    private void OnRequestResponse(WitResponseNode response)
    {
        string text = response["text"];
        if (!string.IsNullOrEmpty(text))
        {
            SetRecordedMessage(text);
            _textBox.text = "\""+text+"\"";
            discussionManager.AskButtonCallback(text);
            //haptic response
            VibrateController();
        }
        OnRequestComplete();
    }

    // Request error
    private void OnRequestError(string error, string message)
    {
        OnRequestComplete();
    }
    // Deactivate
    private void OnRequestComplete()
    {
        _active = false;
    }

    // Toggle activation
    public void ToggleActivation()
    {
        SetActivation(!_active);
    }
    // Set activation
    public void SetActivation(bool toActivated)
    {
        if (_active != toActivated)
        {
            _active = toActivated;
            if (_active)
            {
                appVoiceExperience.Activate();
            }
            else
            {
                appVoiceExperience.Deactivate();
            }
        }
    }
    private void VibrateController()
    {
        OVRInput.SetControllerVibration(50f, 0.05f, OVRInput.Controller.LTouch);
    }
}