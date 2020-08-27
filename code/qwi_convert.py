import csv
import json

RAW = "data/raw"

def json_to_csv():
    with open(RAW + "/statefips.txt", "r") as f:
        statefips = [l.strip() for l in f]
    with open(RAW + "/qwi.csv", "w") as f:
        csvwriter = csv.writer(f, quoting=csv.QUOTE_NONE)
        csvwriter.writerow(["sex","agegrp","Emp","EarnS","time","state","county"])
        for statefip in statefips:
            print(statefip)
            with open(RAW + "/qwi_json/" + statefip + ".json", "r") as f:
                j = json.load(f)
            csvwriter.writerows(j[1:])

if __name__ == "__main__":
    json_to_csv()
