for year in range(2000, 2017):
    print(year)

    inp = open("txt/zipcode_"+str(year)+".txt", "r")
    out = open("csv/prescriptions_"+str(year)+".csv", "w")

    out.write("ZIPCODE,DRUGCODE,Q1,Q2,Q3,Q4\n")

    drugcode = ""
    for line in inp:
        if line.isspace():
            continue
        line = line.lstrip()
        assert line, str(line)

        if line.startswith("DRUG CODE:"):
            begin = 10
            end = line.find("DRUG NAME:")
            if end == -1:
                end = line.find("DRUGNAME:")
            if end == -1:
                assert False, line
            drugcode = line[begin:end].strip()
            assert drugcode.isalnum(), line
        elif str(line[:2]).isdigit():
            strarr = line.split()
            if len(strarr) == 1:
                continue
            for i in range(5):
                strarr[i] = strarr[i].replace(',','')
                if not strarr[i].replace('.','',1).isdigit():
                    assert False, strarr[i]
            assert 2 <= len(strarr[0]) <= 3, str(line)
            if len(strarr[0]) == 2:
                strarr[0] = "0"+strarr[0]
            toadd = ','.join([strarr[0], drugcode, strarr[1], strarr[2], strarr[3], strarr[4]])+'\n'
            out.write(toadd)

    inp.close()
    out.close()
