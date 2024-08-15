using UnityEngine;
using System.Collections.Generic;
using System.IO;
using System.Text;
#if UNITY_EDITOR
using UnityEditor;
#endif

public class MovementRecorder : MonoBehaviour
{
    public GameObject targetObject; // The object to record
    public string fileName = "RecordedMovement.csv"; // Name of the file to save

    [SerializeField] private bool recording = false; // Control recording state
    private bool wasRecording = false; // To track changes in recording state

    private List<string> recordedData = new List<string>();

    void Start()
    {
        // Initialize the CSV header
        recordedData.Add("PositionX,PositionY,PositionZ,RotationX,RotationY,RotationZ,RotationW");
        wasRecording = recording;
    }

    void Update()
    {
        // Check if recording state has changed
        if (wasRecording && !recording)
        {
            SaveRecording();
        }
        wasRecording = recording;

        if (recording && targetObject != null)
        {
            RecordTransform();
        }
    }

    void RecordTransform()
    {
        Vector3 position = targetObject.transform.position;
        Quaternion rotation = targetObject.transform.rotation;

        string dataLine = $"{position.x},{position.y},{position.z},{rotation.x},{rotation.y},{rotation.z},{rotation.w}";
        recordedData.Add(dataLine);
    }

    [ContextMenu("Toggle Recording")]
    public void ToggleRecording()
    {
        recording = !recording;
        if (recording)
        {
            StartRecording();
        }
        else
        {
            StopRecording();
        }
    }

    public void StartRecording()
    {
        recording = true;
        Debug.Log("Recording started");
    }

    public void StopRecording()
    {
        recording = false;
        Debug.Log("Recording stopped");
        SaveRecording();
    }

    private void SaveRecording()
    {
        if (recordedData.Count <= 1) // Only has header
        {
            Debug.LogWarning("No data to save!");
            return;
        }

        string path = GetSaveFilePath();
        if (string.IsNullOrEmpty(path)) return;

        try
        {
            File.WriteAllLines(path, recordedData, Encoding.UTF8);
            Debug.Log($"Recording saved to {path}");
            
            // Clear the recorded data after saving
            recordedData.Clear();
            recordedData.Add("PositionX,PositionY,PositionZ,RotationX,RotationY,RotationZ,RotationW");

            #if UNITY_EDITOR
            AssetDatabase.Refresh();
            #endif
        }
        catch (System.Exception e)
        {
            Debug.LogError($"Failed to save recording: {e.Message}");
        }
    }

    private string GetSaveFilePath()
    {
        #if UNITY_EDITOR
        // Save in the Assets folder
        string path = Path.Combine("Assets", fileName);
        return Path.GetFullPath(path);
        #else
        // For builds, save in persistent data path
        return Path.Combine(Application.persistentDataPath, fileName);
        #endif
    }
}