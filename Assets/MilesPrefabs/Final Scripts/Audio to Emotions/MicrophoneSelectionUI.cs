using UnityEngine;
using TMPro;

public class MicrophoneSelectionUI : MonoBehaviour
{
    [SerializeField] private TMP_Dropdown dropdownUser1;
    [SerializeField] private TMP_Dropdown dropdownUser2;
    [SerializeField] private MicrophoneRecorderManager recorderManager;

    private void Start()
    {
        if (recorderManager == null)
        {
            recorderManager = FindObjectOfType<MicrophoneRecorderManager>();
        }

        if (recorderManager != null)
        {
            PopulateMicrophoneDropdowns();
        }
        else
        {
            Debug.LogError("MicrophoneRecorderManager not found in the scene.");
        }
    }

    private void PopulateMicrophoneDropdowns()
    {
        var microphones = Microphone.devices;

        dropdownUser1.ClearOptions();
        dropdownUser1.AddOptions(new System.Collections.Generic.List<string>(microphones));
        dropdownUser1.onValueChanged.AddListener(delegate { OnMicrophoneSelected(dropdownUser1, true); });

        dropdownUser2.ClearOptions();
        dropdownUser2.AddOptions(new System.Collections.Generic.List<string>(microphones));
        dropdownUser2.onValueChanged.AddListener(delegate { OnMicrophoneSelected(dropdownUser2, false); });
    }

    private void OnMicrophoneSelected(TMP_Dropdown dropdown, bool isUser1)
    {
        string selectedMicrophone = dropdown.options[dropdown.value].text;
        recorderManager.SetMicrophone(selectedMicrophone, isUser1);
    }
}