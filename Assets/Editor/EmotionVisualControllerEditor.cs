using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
[CustomEditor(typeof(EmotionVisualController))]
public class EmotionVisualControllerEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        if (GUILayout.Button("Add New Emotion to All Materials"))
        {
            AddNewEmotionToAllMaterials();
        }
    }

    private void AddNewEmotionToAllMaterials()
    {
        EmotionVisualController controller = (EmotionVisualController)target;

        string newEmotion = "Sad"; // Name of the new emotion
        Texture2D defaultTexture = null;  // Default texture for the new emotion

        // Access materialTextureSets via the getter
        List<EmotionVisualController.MaterialTextureSet> materialTextureSets = controller.GetMaterialTextureSets();

        foreach (var materialSet in materialTextureSets)
        {
            // Check if the emotion already exists
            if (materialSet.textures.Exists(texture => texture.emotion == newEmotion))
            {
                Debug.LogWarning($"Emotion {newEmotion} already exists for material {materialSet.material.name}");
                continue;
            }

            // Create a new TextureData for the new emotion
            EmotionVisualController.TextureData newTextureData = new EmotionVisualController.TextureData
            {
                emotion = newEmotion,
                texture = defaultTexture
            };

            // Add the new TextureData to the material set
            materialSet.textures.Add(newTextureData);
        }

        // Mark the object as dirty to ensure changes are saved
        EditorUtility.SetDirty(controller);
        Debug.Log("Added new emotion to all materials.");
    }
}
