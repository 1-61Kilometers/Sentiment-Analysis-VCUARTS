import os
import shutil
from difflib import get_close_matches

def organize_materials(materials_folder, base_maps_folder):
    # Get list of all material files
    material_files = [f for f in os.listdir(materials_folder) if f.endswith('.mat')]
    
    # Get list of all base map folders
    base_map_folders = [f for f in os.listdir(base_maps_folder) if os.path.isdir(os.path.join(base_maps_folder, f))]
    
    for material in material_files:
        material_name = os.path.splitext(material)[0]  # Remove .mat extension
        meta_file = material + '.meta'
        
        # Try to find a matching folder
        matches = get_close_matches(material_name, base_map_folders, n=1, cutoff=0.6)
        
        if matches:
            matching_folder = matches[0]
            source_mat_path = os.path.join(materials_folder, material)
            source_meta_path = os.path.join(materials_folder, meta_file)
            destination_mat_path = os.path.join(base_maps_folder, matching_folder, material)
            destination_meta_path = os.path.join(base_maps_folder, matching_folder, meta_file)
            
            # Move the material file
            shutil.move(source_mat_path, destination_mat_path)
            print(f"Moved '{material}' to '{matching_folder}' folder")
            
            # Move the meta file if it exists
            if os.path.exists(source_meta_path):
                shutil.move(source_meta_path, destination_meta_path)
                print(f"Moved '{meta_file}' to '{matching_folder}' folder")
            else:
                print(f"Warning: Meta file for '{material}' not found")
        else:
            print(f"No matching folder found for '{material}'. Skipping.")


materials_folder = r'E:\Facial-Tracking-Test-World\Assets\Finished3D\FINISHED COURTROOM\Materials'
base_maps_folder = r'E:\Facial-Tracking-Test-World\Assets\Finished3D\FINISHED COURTROOM'

organize_materials(materials_folder, base_maps_folder)

