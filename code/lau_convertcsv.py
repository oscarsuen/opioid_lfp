out = open("csv/lau_cty.csv", 'w')
out.write("county, year, labforce, employed\n")

for year in range(2000, 2017):
    suffix = str(year)[2:]
    print(suffix)
    inp = open("txt/laucnty"+suffix+".txt", 'r')

    for line in inp:
        if not line.startswith("CN"):
            continue
        strarr = line.split()

        assert strarr[1].isdecimal() and strarr[2].isdecimal(), line
        county = strarr[1]+strarr[2]

        i = 3
        while not strarr[i].isdecimal():
            i += 1
        assert strarr[i].isdecimal(), line
        assert 2000 <= int(strarr[i]) <= 2016, line
        year = strarr[i]

        labforce = strarr[i+1].replace(',','')
        assert labforce.isdecimal() or labforce=="N.A.", line
        if labforce=="N.A.":
            labforce = ""

        employed = strarr[i+2].replace(',','')
        assert employed.isdecimal() or employed=="N.A.", line
        if employed=="N.A.":
            employed = ""

        toadd = ','.join([county, year, labforce, employed])+'\n'
        out.write(toadd)

    inp.close()
out.close()
