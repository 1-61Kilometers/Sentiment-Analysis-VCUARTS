using UnityEngine;

public class StringToColorConverter : MonoBehaviour
{
    public static Vector4 ConvertStringToColor(string input)
    {
        switch (input.ToLower())
        {
            case "hope":
                return new Vector4(1, 1, 0, 1); // Yellow
            case "anxiety":
                return new Vector4(0, 1, 0, 1); // Green
            case "loneliness":
                return new Vector4(0.5f, 0.8f, 1, 1); // Light Blue
            case "sadness":
                return new Vector4(0, 0, 0.8f, 1); // Dark Blue
            case "determination":
                return new Vector4(1, 1, 1, 1); // White
            case "joy":
                return new Vector4(1, 0, 0, 1); // Red
            default:
                return new Vector4(0, 0, 0, 1); // Black (default)
        }
    }
}