import csv
import json

def json_to_csv():
    with open("code/statefips.txt", "r") as f:
        statefips = [l.strip() for l in f]
    for statefip in statefips:
        print(statefip)
        if statefip == "48":
            continue
        with open("json/" + statefip + ".json", "r") as f:
            j = json.load(f)
        with open("csv/" + statefip + ".csv", "w") as f:
            csvwriter = csv.writer(f, quoting=csv.QUOTE_NONE)
            csvwriter.writerows(j)

if __name__ == "__main__":
    json_to_csv()
