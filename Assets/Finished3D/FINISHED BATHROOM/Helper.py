import os
import shutil

def copy_shadergraph_to_subfolders(source_dir):
    # Get the full path of the source file
    source_file = os.path.join(source_dir, 'Dummy.shadergraph')
    
    # Check if the source file exists
    if not os.path.isfile(source_file):
        print(f"Error: 'Dummy.shadergraph' not found in {source_dir}")
        return

    # Iterate through all items in the source directory
    for item in os.listdir(source_dir):
        item_path = os.path.join(source_dir, item)
        
        # Check if the item is a directory
        if os.path.isdir(item_path):
            # Create the new filename based on the folder name
            new_filename = f"{item}.shadergraph"
            destination_file = os.path.join(item_path, new_filename)
            
            # Copy the file
            shutil.copy2(source_file, destination_file)
            print(f"Copied 'Dummy.shadergraph' to '{destination_file}'")

# Usage
source_directory = '.'  # Current directory, change this if needed
copy_shadergraph_to_subfolders(source_directory)