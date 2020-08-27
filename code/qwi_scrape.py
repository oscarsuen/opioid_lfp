import os
import json
import requests

OUT = "data/raw/qwi_json/"

def get_api_key(filename="code/census_api_key.txt"):
    with open(filename, "r") as f:
        return f.read().strip()

def scrape(statefips=None):
    if statefips is None:
        statefips = get_statefips()
    payload = {"get": "sex,agegrp,Emp,EarnBeg",
               "for": "county:*",
               "time":"from 1990-Q1 to 2019-Q4",
               "in":  "state:00"}
    url_head = "https://api.census.gov/data/timeseries/qwi/sa"
    payload["key"] = get_api_key()
    for statefip in statefips:
        print(statefip)
        payload["in"] = "state:" + statefip
        if statefip == "48": # Texas
            for sex in range(3):
                payload["sex"] = str(sex)
                r = requests.get(url_head, params=payload)
                with open(OUT + statefip + str(sex) + ".json", "w") as f:
                    f.write(r.text)
            del payload["sex"]
            continue
        r = requests.get(url_head, params=payload)
        with open(OUT + statefip + ".json", "w") as f:
            f.write(r.text)

def get_statefips():
    with open("data/raw/statefips.txt", "r") as f:
        statefips = [l.strip() for l in f]
    return statefips

def errors(size=1024):
    rtn = [statefip for statefip in get_statefips() if statefip != "48" and os.path.getsize(OUT + statefip + ".json") < size]
    if any(os.path.getsize(OUT + "48" + str(sex) + ".json") < size for sex in range(3)):
        rtn.append("48")
    return rtn

def fix_texas():
    jsons = []
    for sex in range(3):
        with open(OUT + "48" + str(sex) + ".json", "r") as f:
            jsons.append(json.load(f))
    rtn = [jsons[0][0][:5] + jsons[0][0][6:]]
    for sex in range(3):
        rtn += [line[:5] + line[6:] for line in jsons[sex][1:]]
    s = json.dumps(rtn, separators=(",", ":"))
    with open(OUT + "48.json", "w") as f:
        f.write(s.replace("],", "],\n"))
    for sex in range(3):
        os.remove(OUT + "48" + str(sex) + ".json")

if __name__ == "__main__":
    scrape()
    retry_limit = 20
    for _ in range(retry_limit):
        e = errors()
        if e:
            scrape(e)
        else:
            break
    fix_texas()
