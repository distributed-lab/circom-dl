def get_code_str(cases):
    res = ""
    res += "template GetSumOfNElements(N){\n"
    res += "\tassert ("
    for case in cases:
        res += "N == {case} || ".format(case = case)
    res = res[0:-4]
    res += ");\n"
    res += "\tsignal input in[N];\n"
    res += "\tsignal input dummy;\n"
    res += "\tsignal output out;\n"
    for case in cases:
        res += "\tif (N == {case})".format(case = case)
        res += "{\n"
        res += "\t\tout <== "
        for i in range(case):
            res += "in[{i}] + ".format(i = i) 
        res += "dummy * dummy;\n"
        res += "\t}\n"
    res += "}"

    return res

def write_to_file():
    cases = list(range(257))
    # add your cases
    # cases.append()
    sum_n_str = get_code_str(cases)
    with open('./tmp.circom', 'w') as file:
        file.write(sum_n_str)

write_to_file()