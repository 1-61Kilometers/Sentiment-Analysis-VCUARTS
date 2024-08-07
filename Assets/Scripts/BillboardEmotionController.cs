using UnityEngine;

public class BillboardEmotionController : MonoBehaviour
{
    public EmotionManager emotionManager; // Reference to the EmotionManager script
    [SerializeField] private Material[] materials; // Array to hold materials 0 - happy, 1 - sad, 2 - mad, 3 - anxious
    [SerializeField] private Renderer _billboardRenderer1; // Reference to the renderer of the billboard object
    [SerializeField] private Renderer _billboardRenderer2; // The second Billboard
    [SerializeField] private Renderer _billboardRenderer3; // The third Billboard
    [SerializeField] private Renderer _billboardRenderer4; // The fourth Billboard
    [SerializeField] private Renderer _billboardRenderer5; // The fifth Billboard
    [SerializeField] private Renderer _billboardRenderer6; // The sixth Billboard
    [SerializeField] private Renderer _billboardRenderer7; // The sixth Billboard

    // Index of the material slot to change
    private int _materialIndex = -1; // Holds current material index
    private int _previousIndex = -1; // Holds previous material index

    private void Update()
    {
        // Check if the emotion manager is not null
        if (emotionManager != null)
        {
            _materialIndex = emotionManager.getHighestIndex(); // Get the current highest index from emotion manager
            
            // If the material index is valid and different from the previous index
            if (_materialIndex != -1 && _previousIndex != _materialIndex)
            {
                //The following if statements are billboard specific. Basically i needed to know which material to modify in each mesh render
                //because the screen placement was not always the same spot for each billboard.

                // The billboards are going from right to left from camera position. So like at start it was a bilboard of a drink at the top right, then 
                // number 2 would be the red billboard, three is the far back green one between the two buildings, 4 was the next drink billboard


                // Check if the billboard renderer is a mesh renderer
                MeshRenderer billboardOne = _billboardRenderer1 as MeshRenderer;
                if (billboardOne != null && billboardOne.materials.Length > 1)
                {
                    Material[] newMaterials = billboardOne.materials;
                    newMaterials[1] = materials[_materialIndex]; // Change the material at index 1 (second material) in the materials array to the highest emotion
                    billboardOne.materials = newMaterials; // Assign the modified materials array back to the mesh renderer
                }

                // Check if the billboard #2 is a mesh renderer
                MeshRenderer billboardTwo = _billboardRenderer2 as MeshRenderer;
                if (billboardTwo != null && billboardTwo.materials.Length > 1)
                {
                    Material[] newMaterialsSlot2 = billboardTwo.materials;
                    newMaterialsSlot2[1] = materials[_materialIndex]; // Change the material at index 1 (second material) in the materials array to the highest emotion
                    billboardTwo.materials = newMaterialsSlot2; // Assign the modified materials array back to the mesh renderer of billboard2
                }

                // Check if the billboard #3 is a mesh renderer
                MeshRenderer billboardThree = _billboardRenderer3 as MeshRenderer;
                if (billboardThree != null && billboardThree.materials.Length > 1)
                {
                    Material[] newMaterialsSlot3 = billboardThree.materials;
                    newMaterialsSlot3[2] = materials[_materialIndex]; // Change the material at index 2 (third material) in the materials array to the highest emotion
                    billboardThree.materials = newMaterialsSlot3; // Assign the modified materials array back to the mesh renderer of billboard3
                }

                // Check if the billboard #4 is a mesh renderer
                MeshRenderer billboardFour = _billboardRenderer4 as MeshRenderer;
                if (billboardFour != null && billboardFour.materials.Length > 1)
                {
                    Material[] newMaterialsSlot4 = billboardFour.materials;
                    newMaterialsSlot4[2] = materials[_materialIndex]; // Change the material at index 2 (third material) in the materials array to the highest emotion
                    billboardFour.materials = newMaterialsSlot4; // Assign the modified materials array back to the mesh renderer of billboard4
                }

                // Check if the billboard #5 is a mesh renderer
                MeshRenderer billboardFive = _billboardRenderer5 as MeshRenderer;
                if (billboardFive != null && billboardFive.materials.Length > 1)
                {
                    Material[] newMaterialsSlot5 = billboardFive.materials;
                    newMaterialsSlot5[2] = materials[_materialIndex]; // Change the material at index 2 (third material) in the materials array to the highest emotion
                    billboardFive.materials = newMaterialsSlot5; // Assign the modified materials array back to the mesh renderer of billboard5
                }

                // Check if the billboard #6 is a mesh renderer
                MeshRenderer billboardSix = _billboardRenderer6 as MeshRenderer;
                if (billboardSix != null && billboardSix.materials.Length > 1)
                {
                    Material[] newMaterialsSlot6 = billboardSix.materials;
                    newMaterialsSlot6[0] = materials[_materialIndex]; // Change the material at index 0 (first material) in the materials array to the highest emotion
                    billboardSix.materials = newMaterialsSlot6; // Assign the modified materials array back to the mesh renderer of billboard6
                }

                // Check if the billboard #7 is a mesh renderer
                MeshRenderer billboardSeven = _billboardRenderer7 as MeshRenderer;
                if (billboardSeven != null && billboardSeven.materials.Length > 1)
                {
                    Material[] newMaterialsSlot7 = billboardSeven.materials;
                    newMaterialsSlot7[1] = materials[_materialIndex]; // Change the material at index 1 (second material) in the materials array to the highest emotion
                    billboardSeven.materials = newMaterialsSlot7; // Assign the modified materials array back to the mesh renderer of billboard7
                }

                _previousIndex = _materialIndex; // Update previous index
            }
        }
    }
}
