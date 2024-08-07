using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using UnityEngine.UI;
using System;

public class DiscussionBubble : MonoBehaviour
{
    [Header(" Elements ")]
    [SerializeField] private TextMeshProUGUI messageText;
    [SerializeField] private Image bubbleImage;
    [SerializeField] private Sprite userBubbleSprite;
    [SerializeField] private GameObject voiceButton;
    [Header(" Settings ")]
    [SerializeField] private Color userBubbleColor;

    [Header("Events")]
    public static Action<string> onVoiceButtonClicked;


    public void Configure(string message, bool isUserMessage)
    {
        if (isUserMessage)
        {
            bubbleImage.sprite = userBubbleSprite;
            bubbleImage.color = userBubbleColor;
            messageText.color = Color.white;

            voiceButton.SetActive(false);
        }
        messageText.text = message;
        messageText.ForceMeshUpdate();

    }

    public void VoiceButtonCallback()
    {
        onVoiceButtonClicked?.Invoke(messageText.text);
    }

    public void CopyToClipboardCallback()
    {
       GUIUtility.systemCopyBuffer=messageText.text;
    }
}
