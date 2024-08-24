using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class EmotionVisualController : MonoBehaviour
{
    [System.Serializable]
    public class TextureData
    {
        public string emotion;
        public Texture2D texture;
    }

    [System.Serializable]
    public class MaterialTextureSet
    {
        public Material material;
        public List<TextureData> textures = new List<TextureData>();
    }

    // New lighting preset class
    [System.Serializable]
    public class LightingPreset
    {
        public string emotion;
        public Color ambientColor;
        public Color directionalLightColor;
        public float directionalLightIntensity;
    }

    [SerializeField] private EmotionTracker emotionTracker;
    [SerializeField] private List<MaterialTextureSet> materialTextureSets = new List<MaterialTextureSet>();
    [SerializeField] private float transitionDuration = 1f;

    // New fields for lighting
    [SerializeField] private List<LightingPreset> lightingPresets = new List<LightingPreset>();
    [SerializeField] private Light directionalLight;

    private Dictionary<Material, Coroutine> transitionCoroutines = new Dictionary<Material, Coroutine>();
    // New coroutine for lighting transition
    private Coroutine lightingTransitionCoroutine;

    private void Start()
    {
        InitializeComponents();
    }

    private void InitializeComponents()
    {
        if (emotionTracker == null)
        {
            emotionTracker = FindObjectOfType<EmotionTracker>();
            if (emotionTracker == null)
            {
                Debug.LogError("EmotionVisualController: EmotionTracker not found in the scene!");
                enabled = false;
                return;
            }
        }

        // Initialize directional light if not set
        if (directionalLight == null)
        {
            directionalLight = FindObjectOfType<Light>();
            if (directionalLight == null || directionalLight.type != LightType.Directional)
            {
                Debug.LogWarning("EmotionVisualController: Directional light not found or set. Lighting transitions will be disabled.");
            }
        }

        emotionTracker.OnEmotionsUpdated += UpdateVisuals;

        // Initialize materials
        foreach (var materialSet in materialTextureSets)
        {
            materialSet.material.SetTexture("_BaseMap", materialSet.textures[0].texture);
            materialSet.material.SetTexture("_BaseMap1", materialSet.textures[0].texture);
            materialSet.material.SetFloat("_BlendFactor", 0);
        }

        // Initialize with the current emotion
        UpdateVisuals();
    }

    private void UpdateVisuals()
    {
        string currentEmotion = emotionTracker.MainEmotion;
        if(currentEmotion == "Lonely")
        {
            currentEmotion = "Sad";
        }
        foreach (var materialSet in materialTextureSets)
        {
            TextureData targetTextureData = GetTextureDataForEmotion(materialSet, currentEmotion);
            if (targetTextureData == null)
            {
                Debug.LogWarning($"EmotionVisualController: No texture data found for emotion {currentEmotion} in material {materialSet.material.name}");
                continue;
            }

            if (transitionCoroutines.TryGetValue(materialSet.material, out Coroutine existingCoroutine))
            {
                StopCoroutine(existingCoroutine);
            }

            Coroutine newCoroutine = StartCoroutine(TransitionTexture(materialSet.material, targetTextureData.texture));
            transitionCoroutines[materialSet.material] = newCoroutine;
        }

        // New: Update lighting
        UpdateLighting(currentEmotion);
    }

    private TextureData GetTextureDataForEmotion(MaterialTextureSet materialSet, string emotion)
    {
        return materialSet.textures.Find(data => data.emotion == emotion) ?? materialSet.textures[0];
    }

    private IEnumerator TransitionTexture(Material material, Texture2D targetTexture)
    {
        
        Texture2D currentTexture = material.GetTexture("_BaseMap") as Texture2D;

        material.SetTexture("_BaseMap", currentTexture);
        material.SetTexture("_BaseMap1", targetTexture);

        float elapsedTime = 0f;
        while (elapsedTime < transitionDuration)
        {
            elapsedTime += Time.deltaTime;
            float t = Mathf.Clamp01(elapsedTime / transitionDuration);

            material.SetFloat("_BlendFactor", t);

            yield return null;
        }

        // Ensure we end at the target texture
        material.SetTexture("_BaseMap", targetTexture);
        material.SetFloat("_BlendFactor", 0);
    }

    private void OnDisable()
    {
        if (emotionTracker != null)
        {
            emotionTracker.OnEmotionsUpdated -= UpdateVisuals;
        }
    }

    // New methods for lighting

    private void UpdateLighting(string currentEmotion)
    {
        if (directionalLight == null) return;

        LightingPreset targetPreset = GetLightingPresetForEmotion(currentEmotion);
        if (targetPreset != null)
        {
            if (lightingTransitionCoroutine != null)
            {
                StopCoroutine(lightingTransitionCoroutine);
            }
            lightingTransitionCoroutine = StartCoroutine(TransitionLighting(targetPreset));
        }
    }

    private LightingPreset GetLightingPresetForEmotion(string emotion)
    {
        return lightingPresets.Find(preset => preset.emotion == emotion) ?? lightingPresets[0];
    }

    private IEnumerator TransitionLighting(LightingPreset targetPreset)
    {
        Color startAmbientColor = RenderSettings.ambientLight;
        Color startDirectionalLightColor = directionalLight.color;
        float startDirectionalLightIntensity = directionalLight.intensity;

        float elapsedTime = 0f;
        while (elapsedTime < transitionDuration)
        {
            elapsedTime += Time.deltaTime;
            float t = Mathf.Clamp01(elapsedTime / transitionDuration);

            RenderSettings.ambientLight = Color.Lerp(startAmbientColor, targetPreset.ambientColor, t);
            directionalLight.color = Color.Lerp(startDirectionalLightColor, targetPreset.directionalLightColor, t);
            directionalLight.intensity = Mathf.Lerp(startDirectionalLightIntensity, targetPreset.directionalLightIntensity, t);

            yield return null;
        }

        // Ensure we end at the target lighting settings
        RenderSettings.ambientLight = targetPreset.ambientColor;
        directionalLight.color = targetPreset.directionalLightColor;
        directionalLight.intensity = targetPreset.directionalLightIntensity;
    }
    public List<MaterialTextureSet> GetMaterialTextureSets()
    {
        return materialTextureSets;
    }
}