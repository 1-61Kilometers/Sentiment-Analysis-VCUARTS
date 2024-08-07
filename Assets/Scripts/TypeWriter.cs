using System.Collections;
using TMPro;
using UnityEngine;

public class TypeWriter : MonoBehaviour
{
    [SerializeField] private TextMeshProUGUI textObject;
    [SerializeField] private string[] script;

    private int scriptIndex = 0;

    private void Update()
    {
        //press A -> advance script
        //press B -> go back
        //controller
        if (OVRInput.GetDown(OVRInput.Button.One) || Input.GetMouseButtonDown(0)) 
        {
            if (!(scriptIndex + 1 == script.Length))
            {
                scriptIndex++;
                textObject.text = script[scriptIndex];
            }
        }
        else if (OVRInput.GetDown(OVRInput.Button.Two) || Input.GetMouseButtonDown(1)) 
        {
            if (!(scriptIndex == 0))
            {
                scriptIndex--;
                textObject.text = script[scriptIndex];
            }
        }
    }

}
