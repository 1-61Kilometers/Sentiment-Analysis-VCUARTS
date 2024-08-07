import os
import shutil
from difflib import get_close_matches

def organize_materials(materials_folder, base_maps_folder):
    # Get list of all material files
    material_files = [f for f in os.listdir(materials_folder) if f.endswith('.meta')]
    
    # Get list of all base map folders
    base_map_folders = [f for f in os.listdir(base_maps_folder) if os.path.isdir(os.path.join(base_maps_folder, f))]
    
    for material in material_files:
        material_name = os.path.splitext(material)[0]  # Remove .mat extension
        
        # Try to find a matching folder
        matches = get_close_matches(material_name, base_map_folders, n=1, cutoff=0.6)
        
        if matches:
            matching_folder = matches[0]
            source_path = os.path.join(materials_folder, material)
            destination_path = os.path.join(base_maps_folder, matching_folder, material)
            
            # Move the material file
            shutil.move(source_path, destination_path)
            print(f"Moved '{material}' to '{matching_folder}' folder")
        else:
            print(f"No matching folder found for '{material}'. Skipping.")

# Usage
materials_folder = r'E:\Facial-Tracking-Test-World\Assets\Finished3D\FINISHED BATHROOM\Materials'
base_maps_folder = r'E:\Facial-Tracking-Test-World\Assets\Finished3D\FINISHED BATHROOM'

organize_materials(materials_folder, base_maps_folder)