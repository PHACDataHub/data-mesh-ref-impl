from flask import Flask, render_template, jsonify
import requests

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
    {
        "name": "Governance UI",
        "icon": "svg/Governance UI.svg",
        "url": "https://governance.$$.paradire.phac-aspc.alpha.canada.ca",
    },
    {
        "name": "Patient Browser",
        "icon": "svg/Patient Browser.svg",
        "url": "https://patient-browser.$$.paradire.phac-aspc.alpha.canada.ca",
    },
    {
        "name": "HAPI FHIR Server",
        "icon": "svg/HAPI FHIR Server.svg",
        "url": "https://fhir.$$.paradire.phac-aspc.alpha.canada.ca",
    },
    {
        "name": "Neo4j",
        "icon": "svg/Neo4j.svg",
        "url": "https://neo4j.$$.paradire.phac-aspc.alpha.canada.ca/browser",
        "fed": True,
    },
    {
        "name": "Neodash",
        "icon": "svg/Neodash.svg",
        "url": "https://neodash.$$.paradire.phac-aspc.alpha.canada.ca",
        "fed": True,
    },
    {
        "name": "Kafka UI",
        "icon": "svg/Kafka UI.svg",
        "url": "https://kafkaui.$$.paradire.phac-aspc.alpha.canada.ca",
        "fed": True,
    },
]


@app.route("/")
def index():
    return render_template("planb.html", clusters=clusters, services=services)


def check_health(url):
    try:
        print(url)
        response = requests.get(url, timeout=5, allow_redirects=True)
        return response.status_code in (200, 302)
    except requests.exceptions.RequestException as e:
        print(f"Error checking {url}: {e}")
        return None


@app.route("/health-check/<cluster_name>")
def health_check(cluster_name):
    print(f"Checking health for cluster: {cluster_name}")
    for cluster in clusters:
        if cluster["alpha"] == cluster_name:
            for service in services:
                if "fed" not in cluster or "fed" in service:
                    result = check_health(service["url"].replace("$$", cluster["alpha"]))
                    if result is None:
                        return jsonify({ cluster_name: "unhealthy"})
                    elif not result:
                        return jsonify({ cluster_name: "error"})
            return jsonify({ cluster_name: "healthy"})
    return jsonify({"error": "Province not found"}), 404

if __name__ == "__main__":
    app.run(debug=True)
