using System.Linq;
using UnityEngine;
using System.Collections.Generic;

public class MicrophoneVisualizer : MonoBehaviour
{
    public MicrophoneRecorder microphoneRecorder;
    public int numberOfSamples = 64;
    public float visualizationScale = 50f;
    public float minHeight = 1f;
    public float maxHeight = 100f;
    public float visualizerSpacing = 5f; // Spacing between the two visualizers

    private LineRenderer yetiLineRenderer;
    private LineRenderer webcamLineRenderer;
    private float[] yetiVisualizationData;
    private float[] webcamVisualizationData;

    private void Start()
    {
        Debug.Log("DualMicrophoneVisualizer: Start method called");
        InitializeLineRenderer(ref yetiLineRenderer, "YetiVisualizer");
        InitializeLineRenderer(ref webcamLineRenderer, "WebcamVisualizer");
        yetiVisualizationData = new float[numberOfSamples];
        webcamVisualizationData = new float[numberOfSamples];
        Debug.Log("DualMicrophoneVisualizer: Initialization complete");
    }

    private void InitializeLineRenderer(ref LineRenderer lineRenderer, string name)
    {
        GameObject visualizerObject = new GameObject(name);
        visualizerObject.transform.SetParent(transform);
        
        lineRenderer = visualizerObject.AddComponent<LineRenderer>();
        lineRenderer.positionCount = numberOfSamples;
        lineRenderer.startWidth = 0.1f;
        lineRenderer.endWidth = 0.1f;
        lineRenderer.useWorldSpace = false;

        // Initialize the line renderer with default positions
        for (int i = 0; i < numberOfSamples; i++)
        {
            lineRenderer.SetPosition(i, new Vector3((float)i / numberOfSamples * 10 - 5, 0, 0));
        }

        if (name == "WebcamVisualizer")
        {
            visualizerObject.transform.localPosition = new Vector3(1.1f, -5.003f, 0);
        }
        else
        {
            visualizerObject.transform.localPosition = new Vector3(11.09f, 0, 0);
        }
        Debug.Log($"DualMicrophoneVisualizer: {name} LineRenderer initialized");
    }

    private void Update()
    {
        if (microphoneRecorder == null)
        {
            Debug.LogError("DualMicrophoneVisualizer: MicrophoneRecorder is not set");
            return;
        }

        UpdateVisualizer(microphoneRecorder.yetiMicrophone, yetiLineRenderer, ref yetiVisualizationData, 0);
        UpdateVisualizer(microphoneRecorder.webcamMicrophone, webcamLineRenderer, ref webcamVisualizationData, visualizerSpacing);
    }

    private void UpdateVisualizer(MicrophoneRecorder.MicrophoneSettings microphone, LineRenderer lineRenderer, ref float[] visualizationData, float yOffset)
    {
        float[] samples = GetCurrentAudioSamples(microphone);
        if (samples == null || samples.Length == 0)
        {
            Debug.LogWarning($"DualMicrophoneVisualizer: No audio samples received for {microphone.deviceName}");
            return;
        }

        //Debug.Log($"DualMicrophoneVisualizer: Updating visualization for {microphone.deviceName} with {samples.Length} samples. Max value: {samples.Max()}, Min value: {samples.Min()}");

        for (int i = 0; i < numberOfSamples; i++)
        {
            float height = Mathf.Clamp(Mathf.Abs(samples[i]) * visualizationScale, minHeight, maxHeight);
            visualizationData[i] = height;
            Vector3 position = new Vector3(
                (float)i / numberOfSamples * 10 - 5,
                height + yOffset,
                0
            );
            lineRenderer.SetPosition(i, position);
        }

        //Debug.Log($"DualMicrophoneVisualizer: Visualization updated for {microphone.deviceName}. Max height: {visualizationData.Max()}, Min height: {visualizationData.Min()}");
    }

    private float[] GetCurrentAudioSamples(MicrophoneRecorder.MicrophoneSettings microphone)
    {
        if (microphone.audioClip == null)
        {
            Debug.LogError($"DualMicrophoneVisualizer: No active audio clip for {microphone.deviceName}");
            return null;
        }

        if (!Microphone.IsRecording(microphone.deviceName))
        {
            Debug.LogWarning($"DualMicrophoneVisualizer: Microphone {microphone.deviceName} is not recording");
            return null;
        }

        float[] samples = new float[numberOfSamples];
        int position = Microphone.GetPosition(microphone.deviceName) - (numberOfSamples + 1);
        if (position < 0) position = 0;
        microphone.audioClip.GetData(samples, position);

        return samples;
    }
}