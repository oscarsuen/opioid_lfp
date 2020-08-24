import os
import requests

API_KEY = "700e5d587406baa97aecd07e168f56fb3a3a37e2"

def scrape(statefips=None):
    if statefips is None:
        statefips = get_statefips()
    payload = {"get": "sex,agegrp,Emp,EarnS",
               "for": "county:*",
               "time":"from 1990-Q1 to 2019-Q4",
               "in":  "state:00"}
    payload["key"] = API_KEY
    for statefip in statefips:
        print(statefip)
        payload["in"] = "state:" + statefip
        r = requests.get("https://api.census.gov/data/timeseries/qwi/sa", params=payload)
        with open("json/" + statefip + ".json", "w") as f:
            f.write(r.text)
        print(r.url)

def get_statefips():
    with open("code/statefips.txt", "r") as f:
        statefips = [l.strip() for l in f]
    return statefips

def errors():
    return [statefip for statefip in get_statefips() if os.path.getsize("json/" + statefip + ".json") < 1024]

if __name__ == "__main__":
    # scrape(errors())
    payload = {"get": "sex,agegrp,Emp,EarnS",
               "for": "county:*",
               "time":"from 1990-Q1 to 2019-Q4",
               "in":  "state:00"}
    with open("code/census_api_key.txt", "r") as f:
        payload["key"] = f.read().strip()
    statefip = '48'
    payload["in"] = "state:" + statefip
    for sex in range(3):
        payload["sex"] = str(sex)
        r = requests.get("https://api.census.gov/data/timeseries/qwi/sa", params=payload)
        with open("json/" + statefip + str(sex) + ".json", "w") as f:
            f.write(r.text)
