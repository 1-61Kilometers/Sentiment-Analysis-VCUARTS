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

        if (GUILayout.Button("Rename 'Anger' to 'Angry'"))
        {
            RenameAngerToAngry();
        }
    }

    private void RenameAngerToAngry()
    {
        EmotionVisualController controller = (EmotionVisualController)target;

        // Access materialTextureSets via the getter
        List<EmotionVisualController.MaterialTextureSet> materialTextureSets = controller.GetMaterialTextureSets();

        foreach (var materialSet in materialTextureSets)
        {
            foreach (var textureData in materialSet.textures)
            {
                if (textureData.emotion == "Anger")
                {
                    textureData.emotion = "Angry";
                    Debug.Log($"Renamed 'Anger' to 'Angry' for material {materialSet.material.name}");
                }
            }
        }

        // Mark the object as dirty to ensure changes are saved
        EditorUtility.SetDirty(controller);
        Debug.Log("Completed renaming 'Anger' to 'Angry'.");
    }
}
