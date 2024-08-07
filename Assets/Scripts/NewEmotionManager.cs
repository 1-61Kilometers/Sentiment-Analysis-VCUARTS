using System.Collections;
using UnityEngine;

public class NewEmotionManager : MonoBehaviour
{
    public NetworkManager networkManager; // reference to network manager

    private int[] _emotionsSentiment; // current emotion values in form Happy, Sad, Mad, Anxious
    private int _faceEmotionIndex; // current emotion of face index 0 - Happy, 1 - Sad, 2 - Mad, 3 - Anxious
    private int _faceEmotionValue; // current value of the face emotion

    [SerializeField] private Color _happyColor;
    [SerializeField] private Color _sadColor;
    [SerializeField] private Color _madColor;
    [SerializeField] private Color _anxiousColor;

    [SerializeField] private float _colorTransitionSpeed = 1f; // Speed of color transition
    [SerializeField] private float skyboxRotationSpeed = 1f; // Speed of skybox rotation

    private Color _targetColor;
    private int _highestIndex = -1;
    private Coroutine _changeColorCoroutine;

    private void Start()
    {
        _targetColor = RenderSettings.skybox.GetColor("_Tint");
        InvokeRepeating(nameof(UpdateEmotions), 5.0f, 1f);
        InvokeRepeating(nameof(UpdateEmotionSky), 5.0f, 1f);
        InvokeRepeating(nameof(UpdateSkyRotation), 5.0f, 1f);
        StartCoroutine(RotateSkybox());
    }

    private void UpdateEmotions()
    {
        _emotionsSentiment = networkManager.GetSttEmotionProbs(); // getting voice sentiment
        _faceEmotionIndex = networkManager.GetFaceEmotionIndex(); // getting facial emotion
        _faceEmotionValue = networkManager.GetFaceEmotionValue(); // getting facial emotion value

        if (_emotionsSentiment != null && _emotionsSentiment.Length >= 4)
        {
            _emotionsSentiment[_faceEmotionIndex] = _faceEmotionValue; // adding face value to emotion array
        }
    }

    private void UpdateSkyRotation()
    {
        if (_emotionsSentiment != null && _emotionsSentiment.Length >= 4)
        {
            int index = GetHighestEmotionIndex(_emotionsSentiment); // getting emotion index of the highest emotion
            int level = _emotionsSentiment[index]; // getting the level of the highest emotion

            if (level > 0)
            {
                if (level > 4)
                {
                    skyboxRotationSpeed = (index > 1) ? 4f : (index == 1) ? 0.5f : 1f; // adjust rotation speed based on emotion
                }
            }
        }
    }

    private void UpdateEmotionSky()
    {
        if (_emotionsSentiment != null && _emotionsSentiment.Length >= 4)
        {
            float totalEmotion = _emotionsSentiment[0] + _emotionsSentiment[1] + _emotionsSentiment[2] + _emotionsSentiment[3];

            if (totalEmotion > 0)
            {
                // Calculate the weighted average emotion color based on emotion strengths
                Color emotionColor = (_emotionsSentiment[0] * _happyColor +
                                      _emotionsSentiment[1] * _sadColor +
                                      _emotionsSentiment[2] * _madColor +
                                      _emotionsSentiment[3] * _anxiousColor) / totalEmotion;

                _targetColor = emotionColor;
            }
            else
            {
                _targetColor = _happyColor;
            }

            if (_changeColorCoroutine != null)
            {
                StopCoroutine(_changeColorCoroutine);
            }

            _changeColorCoroutine = StartCoroutine(ChangeSkyColor());
        }
    }

    public int GetHighestEmotionIndex(int[] emotions)
    {
        int highestIndex = 0;
        int highestValue = emotions[0];

        for (int i = 1; i < emotions.Length; i++)
        {
            if (emotions[i] > highestValue)
            {
                highestIndex = i;
                highestValue = emotions[i];
            }
        }

        _highestIndex = highestIndex;
        return highestIndex;
    }

    private IEnumerator ChangeSkyColor()
    {
        while (RenderSettings.skybox.GetColor("_Tint") != _targetColor)
        {
            RenderSettings.skybox.SetColor("_Tint", Color.Lerp(RenderSettings.skybox.GetColor("_Tint"), _targetColor, Time.deltaTime * _colorTransitionSpeed));
            yield return null;
        }
    }

    private IEnumerator RotateSkybox()
    {
        while (true)
        {
            RenderSettings.skybox.SetFloat("_Rotation", Time.time * skyboxRotationSpeed);
            yield return null;
        }
    }

    public int[] GetEmotionArray()
    {
        return _emotionsSentiment;
    }

    private void OnApplicationQuit()
    {
        // Reset sky color to default when the application is quitting
        RenderSettings.skybox.SetColor("_Tint", _happyColor);
        RenderSettings.skybox.SetFloat("_Rotation", 1);
    }

    public int GetHighestIndex()
    {
        return _highestIndex;
    }
}
