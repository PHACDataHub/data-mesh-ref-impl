from flask import Flask, render_template

app = Flask(__name__)

clusters = [
    {"name": "Public Health Agency of Canada", "abbr": {"en": "PHAC", "fr": "ASPC"}, "alpha": "phac", "fed": True},
    {"name": "Newfoundland and Labrador", "abbr": {"en": "N.L.", "fr": "T.-N.-L."}, "alpha": "nl"},
    {"name": "Prince Edward Island", "abbr": {"en": "P.E.I.", "fr": "Î.-P.-É."}, "alpha": "pe"},
    {"name": "Nova Scotia", "abbr": {"en": "N.S.", "fr": "N.-É."}, "alpha": "ns"},
    {"name": "New Brunswick", "abbr": {"en": "N.B.", "fr": "N.-B."}, "alpha": "nb"},
    {"name": "Quebec", "abbr": {"en": "Que.", "fr": "Qc"}, "alpha": "qc"},
    {"name": "Ontario", "abbr": {"en": "Ont.", "fr": "Ont."}, "alpha": "on"},
    {"name": "Manitoba", "abbr": {"en": "Man.", "fr": "Man."}, "alpha": "mb"},
    {"name": "Saskatchewan", "abbr": {"en": "Sask.", "fr": "Sask."}, "alpha": "sk"},
    {"name": "Alberta", "abbr": {"en": "Alta.", "fr": "Alb."}, "alpha": "ab"},
    {"name": "British Columbia", "abbr": {"en": "B.C.", "fr": "C.-B."}, "alpha": "bc"},
    {"name": "Yukon", "abbr": {"en": "Y.T.", "fr": "Yn"}, "alpha": "yt"},
    {"name": "Northwest Territories", "abbr": {"en": "N.W.T.", "fr": "T.N.-O."}, "alpha": "nt"},
    {"name": "Nunavut", "abbr": {"en": "Nvt.", "fr": "Nt"}, "alpha": "nu"},
]

services = [
    {"name": "Governance UI", "icon": None, "url": "https://governance.$$.paradire.phac-aspc.alpha.canada.ca"},
    {
        "name": "Patient Browser",
        "icon": "https://avatars.githubusercontent.com/u/7401080?s=48&v=4",
        "url": "https://patient-browser.$$.paradire.phac-aspc.alpha.canada.ca",
    },
    {
        "name": "HAPI FHIR Server",
        "icon": "https://build.fhir.org/assets/images/fhir-logo-www.png",
        "url": "https://fhir.$$.paradire.phac-aspc.alpha.canada.ca",
    },
    {
        "name": "Neo4J",
        "icon": "https://neodash.graphapp.io/neo4j-icon-color-full.png",
        "url": "https://neo4j.$$.paradire.phac-aspc.alpha.canada.ca/browser",
        "fed": True,
    },
    {"name": "Neodash", "icon": None, "url": "https://neodash.$$.paradire.phac-aspc.alpha.canada.ca", "fed": True},
    {
        "name": "Kafka UI",
        "icon": "https://static-00.iconduck.com/assets.00/kafka-icon-2048x935-cvu4503l.png",
        "url": "https://kafkaui.$$.paradire.phac-aspc.alpha.canada.ca",
        "fed": True,
    },
]


@app.route("/")
def index():
    return render_template("index.html", clusters=clusters, services=services)


if __name__ == "__main__":
    app.run(debug=True)
