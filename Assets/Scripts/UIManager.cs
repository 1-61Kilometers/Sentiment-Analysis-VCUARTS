using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class UIManager : MonoBehaviour
{
    public TextMeshProUGUI sentiment;
    public TextMeshProUGUI stt;
    public TextMeshProUGUI face;

    public void SetSentimentText(string text)
    {
        sentiment.text = "sentiment: " + text;
    }
    public void SetSTTText(string text)
    {
        stt.text = "stt: " + text;
    }
    public void SetFaceText(string text)
    {
        face.text = "expression: " + text;
    }
}
