using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Unity.Sentis;
using TMPro;
using System.Linq;
using Unity.Collections.LowLevel.Unsafe;
using System.Diagnostics;

public class ModelCommunication : MonoBehaviour
{
    public ModelAsset modelAsset;
    Model runtimeModel;
    IWorker worker;
    private int counter;
    public TextMeshProUGUI outputText;
    [SerializeField] private int length1;
    [SerializeField] private int length2;
    public OVRFaceExpressions faceExpressions;

    private void Start()
    {
        runtimeModel = ModelLoader.Load(modelAsset);
        worker = WorkerFactory.CreateWorker(BackendType.GPUCompute, runtimeModel);
        InvokeRepeating("RunModel", 2.0f, 1f);
    }

    private void RunModel()
    {
        Stopwatch stopwatch = new Stopwatch();
        stopwatch.Start();
        counter++;

        if (faceExpressions.FaceTrackingEnabled)
        {
            float[] data = faceExpressions.ToArray();
            TensorShape shape = new TensorShape(length1, length2);
            TensorFloat tensor = new TensorFloat(shape, data);
            worker.Execute(tensor);
            TensorFloat outputTensor = worker.PeekOutput() as TensorFloat;
            outputTensor.CompleteAllPendingOperations();
            outputTensor.MakeReadable();
            float[] outputData = outputTensor.ToReadOnlyArray();

            string[] emotions = { "anxious", "happy", "mad", "sad" };
            int maxIndex = System.Array.IndexOf(outputData, outputData.Max());
            string detectedEmotion = emotions[maxIndex];

            string outputString = $"Detected Emotion: {detectedEmotion}\n\nModel Output:\n" +
                string.Join("\n", outputData.Select((value, index) => $"{emotions[index]}: {value:F4}"));
            if (outputText != null)
            {
                outputText.text = outputString;
            }
            
        }
        else
        {
            if(outputText != null)
            {
                outputText.text = $"Invalid Facial Expressions: {counter}";
            }
            
        }

        stopwatch.Stop();
        UnityEngine.Debug.Log($"RunModel execution time: {stopwatch.ElapsedMilliseconds} ms");
    }

    private void OnDestroy()
    {
        worker?.Dispose();
    }
}