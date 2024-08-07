using System.Collections;
using UnityEngine;

public class EmotionManager : MonoBehaviour
{
    public NetworkManager networkManager; // reference to network manager
    [SerializeField] private GameObject carParentLeft; //reference to gameobject holding all cars going left
    [SerializeField] private GameObject carParentRight; //reference to gameobject holding all cars going right
    [SerializeField] private int numCars = 50; // total number of cars

    private int[] _emotionsSentiment; // current emotion values in form Happy, Sad, Mad, Anxious of sentiment
    private int _faceEmotionIndex; // current emotion of face index 0 - Happy , 1 - Sad, 2 - Mad, 3 - Anxious
    private int _faceEmotionValue; // curent value of the face emotion
    private Car[] _carsLeft; //car array going left
    private Car[] _carsRight; //car array going right
    

    [SerializeField] private Color _happyColor;
    [SerializeField] private Color _sadColor;
    [SerializeField] private Color _madColor;
    [SerializeField] private Color _anxiousColor;
    // Speed of color transition
    [SerializeField] private float _colorTransitionSpeed = 1f;
    //rotation speed
    [SerializeField] private float skyboxRotationSpeed = 1f; // Speed of skybox rotation
    private Color _targetColor;
    private int _highestIndex = -1;
    
    private void Start()
    {

        InitializeCarsArray();
        _targetColor = RenderSettings.skybox.GetColor("_Tint");
        InvokeRepeating("UpdateEmotions", 5.0f, 1f);
        InvokeRepeating("UpdateEmotionSky", 5.0f, 1f);
        InvokeRepeating("UpdateEmotionCar", 5.0f, 1f);
        StartCoroutine(RotateSkybox());
    }
    
    private void UpdateEmotions()
    {
        _emotionsSentiment = networkManager.GetSttEmotionProbs(); //getting voice sentiment
        _faceEmotionIndex = networkManager.GetFaceEmotionIndex(); //getting facial emotion
        _faceEmotionValue = networkManager.GetFaceEmotionValue(); //getting facial emotion value
        if (_emotionsSentiment != null && _emotionsSentiment.Length >= 4) 
        {
            _emotionsSentiment[_faceEmotionIndex] = _faceEmotionValue; //adding face value to emotion array
        }
            
    }
    private void UpdateEmotionCar()
    {
        if (_emotionsSentiment != null && _emotionsSentiment.Length >= 4)
        {
            int index = GetHighestEmotionIndex(_emotionsSentiment); //getting emotion index of the highest emotion
            int level = _emotionsSentiment[index]; //getting the level of the highest emotion
            if (!(level == 0))
            {
                
                int numCarsToEnable = Mathf.RoundToInt(numCars * (1 - (level / 20f))); //how many cars should be enabled/disabled
                

                if (index > 1)
                {
                    for (int i = 0; i < numCars / 2; i++) // Loop through all cars
                    {
                        if (i < numCarsToEnable / 2) // Enable cars up to numCarsToEnable
                        {
                            _carsLeft[i].ToggleCarMesh(true);
                            _carsRight[i].ToggleCarMesh(true);
                        }
                        else // Disable cars beyond numCarsToEnable
                        {
                            _carsLeft[i].ToggleCarMesh(false);
                            _carsRight[i].ToggleCarMesh(false);
                        }
                    }

                }
                else
                {
                    for (int i = 0; i < numCars / 2; i++) // Loop through all cars
                    {
                        if (i < numCarsToEnable / 2) // Enable cars up to numCarsToEnable
                        {
                            _carsLeft[i].ToggleCarMesh(false);
                            _carsRight[i].ToggleCarMesh(false);
                        }
                        else // Disable cars beyond numCarsToEnable
                        {
                            _carsLeft[i].ToggleCarMesh(true);
                            _carsRight[i].ToggleCarMesh(true);
                        }
                    }

                }

                // Adjust car speed based on emotion levels
                float carSpeed = 5f;
                if (level > 4) 
                {
                    if (index > 1) //anxious and mad
                    {
                        carSpeed = 7f;
                        //skybox rotating faster
                        skyboxRotationSpeed = 4f;
                    }
                    else if (index == 1) // sad
                    {
                        carSpeed = 3f;
                        //skybox rotating slower
                        skyboxRotationSpeed = 0.5f;
                    }
                    else //happy
                    {
                        carSpeed = 5f;
                        //skybox rotating normal
                        skyboxRotationSpeed = 1f;
                    }
                }

                
                // Apply speed to enabled cars
                for (int i = 0; i < numCars / 2; i++)
                {
                    _carsLeft[i].SetCarSpeed(carSpeed);
                    _carsRight[i].SetCarSpeed(carSpeed);
                }
            }

        
        }
    }


    private void UpdateEmotionSky()
    {
        
        if(_emotionsSentiment != null && _emotionsSentiment.Length >= 4)
        {
            float totalEmotion = _emotionsSentiment[0] + _emotionsSentiment[1] + _emotionsSentiment[2] + _emotionsSentiment[3];
            Debug.Log("total emotion" + totalEmotion);
            if (totalEmotion > 0)
            {
                
                // Calculate the weighted average emotion color based on emotion strengths
                // todo - change how the color is generated
                Color emotionColor = (_emotionsSentiment[0] * _happyColor +
                                      _emotionsSentiment[1] * _sadColor +
                                      _emotionsSentiment[2] * _madColor +
                                      _emotionsSentiment[3] * _anxiousColor) / totalEmotion;

                _targetColor = emotionColor;
                StartCoroutine(ChangeSkyColor());
            }
            else
            {
                _targetColor = _happyColor;
                StartCoroutine(ChangeSkyColor());
            }
        } 
        
        
    }

    private void InitializeCarsArray()
    {
        
        Transform[] childTransformsLeft = carParentLeft.GetComponentsInChildren<Transform>();
        Transform[] childTransformsRight = carParentRight.GetComponentsInChildren<Transform>();

        
        _carsLeft = new Car[numCars/2];
        _carsRight = new Car[numCars/2];

        
        for (int i = 1; i < childTransformsLeft.Length; i++)
        {
            
            Car carComponentLeft = childTransformsLeft[i].GetComponent<Car>();
            Car carComponentRight = childTransformsRight[i].GetComponent<Car>();
            if (carComponentLeft != null)
            {
                _carsLeft[i - 1] = carComponentLeft;
            }
            if(carComponentRight != null)
            {
                _carsRight[i - 1] = carComponentRight;
            }
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
    public int getHighestIndex()
    {
        
        return _highestIndex;
       
        
    }
}
