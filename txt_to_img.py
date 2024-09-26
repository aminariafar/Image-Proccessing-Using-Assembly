from PIL import Image
import numpy as np

def txt_to_jpg(input_file, output_file):
    try:
        with open(input_file, 'r') as file:
            
            shape_line = file.readline().strip()
            line_one = list(map(int, shape_line.split()))
            grey_flag = line_one[-1]
            shape = line_one[:-1]
           
            data_line = file.readline().strip()
            data = list(map(int, data_line.split()))

            no_of_components = 1
            for x in shape:
                no_of_components *= x
           
            if len(data) != no_of_components:
                raise ValueError("Data size does not match matrix dimensions.")
           
            if (grey_flag):
                shape = tuple([shape[0], shape[1]])
            matrix = np.array(data).reshape(shape)
           
            
            if (grey_flag):
                image = Image.fromarray(matrix.astype(np.uint8), 'L')
            else:
                final_matrix = np.zeros((shape[0], shape[1], 3))
                final_matrix[:, :, :shape[2]] = np.copy(matrix)
                image = Image.fromarray(final_matrix.astype(np.uint8), 'RGB')
                
           
            # Save the image as a JPG file
            image.save(output_file)
            print(f"Image saved as {output_file}.")
   
    except FileNotFoundError:
        print("Input file not found.")
    except ValueError as e:
        print(f"ValueError: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")

# Example usage
input_file = 'output.txt'  # Replace with your input file path
output_file = 'matrix.png'  # Replace with your desired output file path
txt_to_jpg(input_file, output_file)