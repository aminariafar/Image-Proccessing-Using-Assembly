from PIL import Image
import numpy as np

def image_to_txt(input_image_path, output_text_path, grey_flag):

    with Image.open(input_image_path) as img:
        if(grey_flag):
            img = img.convert('L')
        else:
            img = img.convert('RGB')
            
        img_array = np.array(img)
    
    if(grey_flag):
        dim = 1
        height, width = img_array.shape
    else:
        height, width, dim = img_array.shape
    
    # Reshape the array to 2D for saving (rows x columns*3)
    reshaped_array = img_array.reshape(-1, width * dim)
    
    # Write the dimensions and array to a text file without newlines at the end of each row
    with open(output_text_path, 'w') as f:
        # Write the dimensions at rgbthe beginning
        if (grey_flag):
            flag = 1
        else:
            flag = 0
        f.write(f"{height} {width} {dim} {flag}\n")
        for row in reshaped_array:
            # Convert each row to a string of space-separated integers and write to file
            row_str = ' '.join(map(str, row))
            f.write(row_str + ' ')

# Example usage
input_image_path = './unnamed.jpg'
output_text_path = './unnamed.txt'
x = input('Which image mode?(rgb/grey)\n')
grey_flag = False if x == 'rgb' else True
image_to_txt(input_image_path, output_text_path, grey_flag)