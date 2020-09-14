import requests

DIR = "data/raw"
ALL_STATES = ("Al01", "Ak02", "Az04", "Ar05", "Ca06", "Co08", "Ct09", "De10", "Dc11", "Fl12", "Ga13", "Hi15", "Id16", "Il17", "In18", "Ia19", "Ks20", "Ky21", "La22", "Me23", "Md24", "Ma25", "Mi26", "Mn27", "Ms28", "Mo29", "Mt30", "Ne31", "Nv32", "Nh33", "Nj34", "Nm35", "Ny36", "Nc37", "Nd38", "Oh39", "Ok40", "Or41", "Pa42", "Ri44", "Sc45", "Sd46", "Tn47", "Tx48", "Ut49", "Vt50", "Va51", "Wa53", "Wv54", "Wi55", "Wy56")
URL_HEAD = "http://mcdc.missouri.edu/cgi-bin/broker"

def payload_gen(g1, g2, wtvar="pop2k", states=ALL_STATES):
    payload = {"_PROGRAM": "apps.geocorr2000.sas",
               "_SERVICE": "MCDC_long",
               "_debug": 0,
               "nozerob": 1,
               "csvout": 1,
               "namoptf": "b",
               "lstfmt": "html",
               "namoptr": "b",
               "kiloms": 0,}
    for key in ["oropt", "counties", "metros", "uaucs", "places", "latitude", "longitude", "locname", "distance", "nrings", "lathi", "latlo", "longhi", "longlo"] + [f"r{i}" for i in range(1, 10+1)]:
        payload[key] = ""
    payload["g1_"] = g1
    payload["g2_"] = g2
    payload["wtvar"] = wtvar
    payload["state"] = states
    return payload

def get_url2(t):
    head = "<li><a href=\""
    tail = "\">CSV "
    prefix = "http://mcdc.missouri.edu"
    return prefix + t[t.index(head)+len(head):t.index(tail)]

def gen_zipcty(filename=f"{DIR}/zipcty.csv"):
    payload = payload_gen("zcta5", "county")
    r = requests.get(URL_HEAD, params=payload)
    url2 = get_url2(r.text)
    r = requests.get(url2)
    with open(filename, "w") as f:
        f.write(r.text)

def gen_pumacty(filename=f"{DIR}/pumacty.csv"):
    payload = payload_gen("puma5", "county")
    r = requests.get(URL_HEAD, params=payload)
    url2 = get_url2(r.text)
    r = requests.get(url2)
    with open(filename, "w") as f:
        f.write(r.text)

if __name__ == "__main__":
    gen_zipcty()
    gen_pumacty()
