using UnityEngine;
using UnityEngine.Networking;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using TMPro;
using Newtonsoft.Json.Linq;

public class NetworkManager : MonoBehaviour
{

    private List<FloatStringPair> floatStringListRF = new List<FloatStringPair>(); // list for holding predictions
    private const string serverURL = "http://172.20.10.2:5000/receive_data"; //use this route to store data
    private const string predictServerURL = "http://172.20.10.2:5000/predict"; //use this route to predict on data only
    //private const string sendSttURL = "http://172.20.10.2:5000/receive_stt"; //use this route to send stt results
    private const string sendVoiceEmotionURL = "http://172.20.10.2:5000/receive_voice_emotion"; //use this route to send voice emotion results

    //172.20.10.2:5000

    //10.247.14.174:5000 school
    //192.168.1.152:5000 home
    //172.20.10.5:5000 josiah
    //expo 10.246.242.156:5000
    //172.20.10.2:5000 iphone
    //10.246.242.156:5000


    private string _predictedEmotionRF; // current emotion of face
    private float _probabilityRF; // current probability of emotion of face
    private int _predictionCounter = 0; //number of facial predictions
    private int _faceEmotionIndex; // facial expression as an index
    private int _faceEmotionWholeValue; //facial express value as an integer
    private int[] _sttEmotionProbs = new int[4] { 0, 0, 0, 0 }; //last emotions of thing said Order: Happy, Sad, Mad, Anxious
    private string _stt; //last thing said



    private string jsonResponse; // String to store the JSON response for either predicting or collecting

    [SerializeField] bool _displayText = false;
    public UIManager uiManager;

    //driver method to SendData(data)
    //reference this function from other scripts to save data
    // this function is for DATA COLLECTION
    public void SendDataToServer(string[] data)
    {
        StartCoroutine(SendData(data));
    }

    //driver method to GetPredicition(data)
    //reference this function from other scripts to get a predicition
    //this function is for DATA PREDICTION
    public void GetPredicitionFromServer(string[] data)
    {
        StartCoroutine(GetPrediction(data));
    }

    
    //driver method to SendVoiceEmotion(data)
    //reference this function from other scripts to send the Voice Emotion Anaylsis to the server
    //this function if for VOICE ANAYLSIS SENDING
    public void SendVoiceEmotionToServer(string data)
    {
        StartCoroutine(SendVoiceEmotion(data));
    }
    //This function Sends Data to /receive_data 
    //Use  this for taking data from the face and saving to a csv for training model later
    IEnumerator SendData(string[] data)
    {
        // Serialize the string array to JSON
        string jsonData = SerializeStringArrayToJson(data);

        using (UnityWebRequest request = new UnityWebRequest(serverURL, "POST"))
        {
            byte[] bodyRaw = Encoding.UTF8.GetBytes(jsonData);
            request.uploadHandler = (UploadHandler)new UploadHandlerRaw(bodyRaw);
            request.downloadHandler = (DownloadHandler)new DownloadHandlerBuffer();
            request.SetRequestHeader("Content-Type", "application/json");

            yield return request.SendWebRequest();

            if (request.result != UnityWebRequest.Result.Success)
            {
                Debug.LogError("Error sending data to server: " + request.error);
            }
            else
            {
                Debug.Log("Facial Data sent successfully!");

                // Save the JSON response to the jsonResponse string
                // From the /receive_data route we should receive a 200 message.
                jsonResponse = request.downloadHandler.text;
                //Debug.Log("Data Collection Results: " + jsonResponse);
            }
        }
    }

    //function to send user data without knowing what emotion they are displaying
    IEnumerator GetPrediction(string[] data)
    {
        string jsonData = SerializeStringArrayToJson(data);

        using (UnityWebRequest request = new UnityWebRequest(predictServerURL, "POST"))
        {
            byte[] bodyRaw = Encoding.UTF8.GetBytes(jsonData);
            request.uploadHandler = (UploadHandler)new UploadHandlerRaw(bodyRaw);
            request.downloadHandler = (DownloadHandler)new DownloadHandlerBuffer();
            request.SetRequestHeader("Content-Type", "application/json");

            yield return request.SendWebRequest();

            if (request.result != UnityWebRequest.Result.Success)
            {
                Debug.LogError("Error sending data to prediction route: " + request.error);
            }
            else
            {
                Debug.Log("Data sent successfully!");

                // Save the JSON response to the jsonResponse string
                //From the /predict route we will receive a prediction
                
                jsonResponse = request.downloadHandler.text;
                

                // Parse JSON response
                JObject json = JObject.Parse(jsonResponse);


                // Extract values from the 'random_forest' dictionary
                _predictedEmotionRF = (string)json["random_forest"]["emotion"];
                _probabilityRF = (float)json["random_forest"]["probability"];

                floatStringListRF.Add(new FloatStringPair(_probabilityRF, _predictedEmotionRF));

               
                if (_displayText)
                    uiManager.SetFaceText(floatStringListRF[_predictionCounter].stringValue + ": " + floatStringListRF[_predictionCounter].floatValue);

                _predictionCounter++;

                _faceEmotionIndex = MapEmotionToInt(_predictedEmotionRF);
                _faceEmotionWholeValue = MultiplyAndRound(_probabilityRF);
            }
        }

    }


    //function to send voice emotion to the backend

    IEnumerator SendVoiceEmotion(string data)
    {
        // Check if the first word is "sorry,"
        string[] words = data.Split(' ');
        if (words.Length > 0 && words[0].ToLower() == "sorry,")
        {
            Debug.LogError("Error: Cannot send data starting with 'sorry,'.");
            yield break; // Exit the coroutine if the data starts with "sorry,"
        }

        // Proceed with sending data
        _sttEmotionProbs = ExtractNumbersFromString(data);

        if (_displayText)
            uiManager.SetSentimentText(data); //sending stt emotion results

        using (UnityWebRequest request = new UnityWebRequest(sendVoiceEmotionURL, "POST"))
        {
            byte[] bodyRaw = Encoding.UTF8.GetBytes(data);
            request.uploadHandler = (UploadHandler)new UploadHandlerRaw(bodyRaw);
            request.downloadHandler = (DownloadHandler)new DownloadHandlerBuffer();
            request.SetRequestHeader("Content-Type", "application/json");

            yield return request.SendWebRequest();

            if (request.result != UnityWebRequest.Result.Success)
            {
                Debug.LogError("Error sending data to prediction route: " + request.error);
            }
            else
            {
                Debug.Log("STT Emotion sent successfully! from network manager");
                //jsonResponse = request.downloadHandler.text;
            }
        }
    }


    // Custom JSON serialization method
    // note - built in toJson method in Unity was not working so this is our work-around
    // todo - add a serializeFloatArrayToJson to save time when just predicting and not collecting
    string SerializeStringArrayToJson(string[] stringArray)
    {
        StringBuilder sb = new StringBuilder();
        sb.Append("[");
        for (int i = 0; i < stringArray.Length; i++)
        {
            if (i > 0)
                sb.Append(",");
            sb.AppendFormat("\"{0}\"", stringArray[i]);
        }
        sb.Append("]");
        return sb.ToString();
    }


    /* this function will take gpt's response and make put all the numbers into an array
     example gpt response

    Full Result Message: Happy: 8/10
    Sad: 0/10
    Mad: 0/10
    Scared: 0/10

    output of function {8,0,0,0}

     */
    int[] ExtractNumbersFromString(string message)
    {
        string[] lines = message.Split(new[] { '\n', '\r' }, System.StringSplitOptions.RemoveEmptyEntries);
        int[] numbers = new int[lines.Length];

        for (int i = 0; i < lines.Length; i++)
        {
            string[] parts = lines[i].Split(':');
            if (parts.Length == 2)
            {
                string numberPart = parts[1].Trim().Split('/')[0].Trim();
                int number;
                if (int.TryParse(numberPart, out number))
                {
                    numbers[i] = number;
                }
                else
                {
                    Debug.LogError($"Error parsing number from line {i + 1}");
                    numbers[i] = 0; // Set to default value
                }
            }
            else
            {
                Debug.LogError($"Invalid line format at line {i + 1}");
                numbers[i] = 0; // Set to default value
            }
        }

        return numbers;
    }

    //function that maps the facial emotion to an index for use in emotion manager
    private int MapEmotionToInt(string emotion)
    {
        switch (emotion.ToLower())
        {
            case "happy":
                return 0;
            case "sad":
                return 1;
            case "mad":
                return 2;
            case "anxious":
                return 3;
            default:
                return -1; 
        }
    }
    //function that mult emotion float by 10 and returns the nearest whole number 
    int MultiplyAndRound(float value)
    {
        return Mathf.RoundToInt(value * 10);
    }
    // Here are are the getter methods for results
    // Getter method for _predictedEmotionRF
    public string GetPredictedEmotionRF()
    {
        return _predictedEmotionRF;
    }

    // Getter method for _probabilityRF
    public float GetProbabilityRF()
    {
        return _probabilityRF;
    }

    // Getter method for _predictionCounter
    public int GetPredictionCounter()
    {
        return _predictionCounter;
    }

    // Getter method for _sttEmotionProbs
    public int[] GetSttEmotionProbs()
    {
        return _sttEmotionProbs;
    }

    // Getter method for _stt
    public string GetStt()
    {
        return _stt;
    }

    public int GetFaceEmotionIndex()
    {
        return _faceEmotionIndex;
    }
    public int GetFaceEmotionValue()
    {
        return _faceEmotionWholeValue;
    }
}


// Define a custom class to represent a pair of float and string for holding emotion and probability
public class FloatStringPair
{
    public float floatValue;
    public string stringValue;

    // Constructor
    public FloatStringPair(float floatValue, string stringValue)
    {
        this.floatValue = floatValue;
        this.stringValue = stringValue;
    }
}