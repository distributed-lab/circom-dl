import math
#This code generates circom precomputed values for inverses with some precisiom 2 ** prec

# Generate Circom function
def generate_circom_function():
    circom_code = """
pragma circom 2.1.6;
    
function getInverseFloat(value) {{
    if (value == 0) {{\n\t\treturn 0;\n\t}}
    {}
    return 0;
}}
"""
    # Generate assignments for values
    # Change precision to yours: 1 / value * 2 ** prec
    # We have precision 50
    assignments = "\n    ".join(
        f"if (value == {value}) {{\n\t\treturn {round(1 / value * 2 ** 50)};\n\t}}" for value in range(1, 1000000))
    return circom_code.format(assignments)

# Generate and save the Circom file
circom_code = generate_circom_function()

# Run from circuits/zkml
with open("tools.circom", "w") as file:
    file.write(circom_code)

print("Circom file generated successfully!")
