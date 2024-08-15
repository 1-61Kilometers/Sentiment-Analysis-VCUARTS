using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneSwitcher : MonoBehaviour
{
    private int currentSceneIndex;
    private const int TotalScenes = 5;

    void Start()
    {
        currentSceneIndex = SceneManager.GetActiveScene().buildIndex;
        Debug.Log($"Starting scene index: {currentSceneIndex}");
    }

    public void SwitchToNextScene()
    {
        int nextSceneIndex = (currentSceneIndex + 1) % TotalScenes;
        Debug.Log($"Switching to scene index: {nextSceneIndex}");
        
        if (nextSceneIndex < 0 || nextSceneIndex >= SceneManager.sceneCountInBuildSettings)
        {
            Debug.LogError($"Invalid scene index: {nextSceneIndex}. Make sure you have {TotalScenes} scenes in Build Settings.");
            return;
        }

        SceneManager.LoadScene(nextSceneIndex);
    }

    // Call this function to switch to the next scene
    public void SwitchScene()
    {
        SwitchToNextScene();
    }
}