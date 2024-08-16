using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(SceneSwitcher))]
public class SceneSwitcherEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        SceneSwitcher sceneSwitcher = (SceneSwitcher)target;

        if (GUILayout.Button("Switch to Next Scene"))
        {
            sceneSwitcher.SwitchScene();
        }
    }
}