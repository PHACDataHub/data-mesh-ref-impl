from flask import Flask, render_template, jsonify
import requests

app = Flask(__name__)

entities = {
    "Federal": [
        {"name": "Neo4j", "url": "https://neo4j.phac.paradire.alpha.phac.gc.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.phac.paradire.alpha.phac.gc.ca"},
        {"name": "Kafka UI", "url": "https://kafkaui.phac.paradire.alpha.phac.gc.ca"}
    ],
    # "Alberta (AB)": [
    #     {"name": "Governance UI", "url": "https://governance.ab.paradire.alpha.phac.gc.ca"},
    #     {"name": "Patient Browser", "url": "https://patient-browser.ab.paradire.alpha.phac.gc.ca"},
    #     {"name": "HAPI FHIR Server", "url": "https://fhir.ab.paradire.alpha.phac.gc.ca"},
    #     {"name": "Neo4j", "url": "https://neo4j.ab.paradire.alpha.phac.gc.ca/browser"},
    #     {"name": "Neodash", "url": "https://neodash.ab.paradire.alpha.phac.gc.ca"},
    #     {"name": "Kafka UI", "url": "https://kafkaui.ab.paradire.alpha.phac.gc.ca"}
    # ],
    "British Columbia (BC)": [
        {"name": "Governance UI", "url": "https://governance.bc.paradire.alpha.phac.gc.ca"},
        {"name": "Patient Browser", "url": "https://patient-browser.bc.paradire.alpha.phac.gc.ca"},
        {"name": "HAPI FHIR Server", "url": "https://fhir.bc.paradire.alpha.phac.gc.ca"},
        {"name": "Neo4j", "url": "https://neo4j.bc.paradire.alpha.phac.gc.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.bc.paradire.alpha.phac.gc.ca"},
        {"name": "Kafka UI", "url": "https://kafkaui.bc.paradire.alpha.phac.gc.ca"}
    ],
    # "Manitoba (MB)": [
    #     {"name": "Governance UI", "url": "https://governance.mb.paradire.alpha.phac.gc.ca"},
    #     {"name": "Patient Browser", "url": "https://patient-browser.mb.paradire.alpha.phac.gc.ca"},
    #     {"name": "HAPI FHIR Server", "url": "https://fhir.mb.paradire.alpha.phac.gc.ca"},
    #     {"name": "Neo4j", "url": "https://neo4j.mb.paradire.alpha.phac.gc.ca/browser"},
    #     {"name": "Neodash", "url": "https://neodash.mb.paradire.alpha.phac.gc.ca"},
    #     {"name": "Kafka UI", "url": "https://kafkaui.mb.paradire.alpha.phac.gc.ca"}
    # ],
    # "New Brunswick (NB)": [
    #     {"name": "Governance UI", "url": "https://governance.nb.paradire.alpha.phac.gc.ca"},
    #     {"name": "Patient Browser", "url": "https://patient-browser.nb.paradire.alpha.phac.gc.ca"},
    #     {"name": "HAPI FHIR Server", "url": "https://fhir.nb.paradire.alpha.phac.gc.ca"},
    #     {"name": "Neo4j", "url": "https://neo4j.nb.paradire.alpha.phac.gc.ca/browser"},
    #     {"name": "Neodash", "url": "https://neodash.nb.paradire.alpha.phac.gc.ca"},
    #     {"name": "Kafka UI", "url": "https://kafkaui.nb.paradire.alpha.phac.gc.ca"}
    # ],
    # "Newfoundland and Labrador (NL)": [
    #     {"name": "Governance UI", "url": "https://governance.nl.paradire.alpha.phac.gc.ca"},
    #     {"name": "Patient Browser", "url": "https://patient-browser.nl.paradire.alpha.phac.gc.ca"},
    #     {"name": "HAPI FHIR Server", "url": "https://fhir.nl.paradire.alpha.phac.gc.ca"},
    #     {"name": "Neo4j", "url": "https://neo4j.nl.paradire.alpha.phac.gc.ca/browser"},
    #     {"name": "Neodash", "url": "https://neodash.nl.paradire.alpha.phac.gc.ca"},
    #     {"name": "Kafka UI", "url": "https://kafkaui.nl.paradire.alpha.phac.gc.ca"}
    # ],
    # "Nova Scotia (NS)": [
    #     {"name": "Governance UI", "url": "https://governance.ns.paradire.alpha.phac.gc.ca"},
    #     {"name": "Patient Browser", "url": "https://patient-browser.ns.paradire.alpha.phac.gc.ca"},
    #     {"name": "HAPI FHIR Server", "url": "https://fhir.ns.paradire.alpha.phac.gc.ca"},
    #     {"name": "Neo4j", "url": "https://neo4j.ns.paradire.alpha.phac.gc.ca/browser"},
    #     {"name": "Neodash", "url": "https://neodash.ns.paradire.alpha.phac.gc.ca"},
    #     {"name": "Kafka UI", "url": "https://kafkaui.ns.paradire.alpha.phac.gc.ca"}
    # ],
    # "Nunavut (NU)": [
    #     {"name": "Governance UI", "url": "https://governance.nu.paradire.alpha.phac.gc.ca"},
    #     {"name": "Patient Browser", "url": "https://patient-browser.nu.paradire.alpha.phac.gc.ca"},
    #     {"name": "HAPI FHIR Server", "url": "https://fhir.nu.paradire.alpha.phac.gc.ca"},
    #     {"name": "Neo4j", "url": "https://neo4j.nu.paradire.alpha.phac.gc.ca/browser"},
    #     {"name": "Neodash", "url": "https://neodash.nu.paradire.alpha.phac.gc.ca"},
    #     {"name": "Kafka UI", "url": "https://kafkaui.nu.paradire.alpha.phac.gc.ca"}
    # ],
    # "Northwest Territories (NT)": [
    #     {"name": "Governance UI", "url": "https://governance.nt.paradire.alpha.phac.gc.ca"},
    #     {"name": "Patient Browser", "url": "https://patient-browser.nt.paradire.alpha.phac.gc.ca"},
    #     {"name": "HAPI FHIR Server", "url": "https://fhir.nt.paradire.alpha.phac.gc.ca"},
    #     {"name": "Neo4j", "url": "https://neo4j.nt.paradire.alpha.phac.gc.ca/browser"},
    #     {"name": "Neodash", "url": "https://neodash.nt.paradire.alpha.phac.gc.ca"},
    #     {"name": "Kafka UI", "url": "https://kafkaui.nt.paradire.alpha.phac.gc.ca"}
    # ],
    "Ontario (ON)": [
        {"name": "Governance UI", "url": "https://governance.on.paradire.alpha.phac.gc.ca"},
        {"name": "Patient Browser", "url": "https://patient-browser.on.paradire.alpha.phac.gc.ca"},
        {"name": "HAPI FHIR Server", "url": "https://fhir.on.paradire.alpha.phac.gc.ca"},
        {"name": "Neo4j", "url": "https://neo4j.on.paradire.alpha.phac.gc.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.on.paradire.alpha.phac.gc.ca"},
        {"name": "Kafka UI", "url": "https://kafkaui.on.paradire.alpha.phac.gc.ca"}
    ]
    # "Prince Edward Island (PE)": [
    #     {"name": "Governance UI", "url": "https://governance.pe.paradire.alpha.phac.gc.ca"},
    #     {"name": "Patient Browser", "url": "https://patient-browser.pe.paradire.alpha.phac.gc.ca"},
    #     {"name": "HAPI FHIR Server", "url": "https://fhir.pe.paradire.alpha.phac.gc.ca"},
    #     {"name": "Neo4j", "url": "https://neo4j.pe.paradire.alpha.phac.gc.ca/browser"},
    #     {"name": "Neodash", "url": "https://neodash.pe.paradire.alpha.phac.gc.ca"},
    #     {"name": "Kafka UI", "url": "https://kafkaui.pe.paradire.alpha.phac.gc.ca"}
    # ],
    # "Quebec (QC)": [
    #     {"name": "Governance UI", "url": "https://governance.qc.paradire.alpha.phac.gc.ca"},
    #     {"name": "Patient Browser", "url": "https://patient-browser.qc.paradire.alpha.phac.gc.ca"},
    #     {"name": "HAPI FHIR Server", "url": "https://fhir.qc.paradire.alpha.phac.gc.ca"},
    #     {"name": "Neo4j", "url": "https://neo4j.qc.paradire.alpha.phac.gc.ca/browser"},
    #     {"name": "Neodash", "url": "https://neodash.qc.paradire.alpha.phac.gc.ca"},
    #     {"name": "Kafka UI", "url": "https://kafkaui.qc.paradire.alpha.phac.gc.ca"}
    # ],
    # "Saskatchewan (SK)": [
    #     {"name": "Governance UI", "url": "https://governance.sk.paradire.alpha.phac.gc.ca"},
    #     {"name": "Patient Browser", "url": "https://patient-browser.sk.paradire.alpha.phac.gc.ca"},
    #     {"name": "HAPI FHIR Server", "url": "https://fhir.sk.paradire.alpha.phac.gc.ca"},
    #     {"name": "Neo4j", "url": "https://neo4j.sk.paradire.alpha.phac.gc.ca/browser"},
    #     {"name": "Neodash", "url": "https://neodash.sk.paradire.alpha.phac.gc.ca"},
    #     {"name": "Kafka UI", "url": "https://kafkaui.sk.paradire.alpha.phac.gc.ca"}
    # ],
    # "Yukon (YT)": [
    #     {"name": "Governance UI", "url": "https://governance.yt.paradire.alpha.phac.gc.ca"},
    #     {"name": "Patient Browser", "url": "https://patient-browser.yt.paradire.alpha.phac.gc.ca"},
    #     {"name": "HAPI FHIR Server", "url": "https://fhir.yt.paradire.alpha.phac.gc.ca"},
    #     {"name": "Neo4j", "url": "https://neo4j.yt.paradire.alpha.phac.gc.ca/browser"},
    #     {"name": "Neodash", "url": "https://neodash.yt.paradire.alpha.phac.gc.ca"},
    #     {"name": "Kafka UI", "url": "https://kafkaui.yt.paradire.alpha.phac.gc.ca"}
    # ]
}

@app.route('/')
def index():
    return render_template('index.html', entities=entities)

def check_health(url):
    try:
        print(url)
        response = requests.get(url, timeout=5, allow_redirects=True)
        return response.status_code in (200, 302)
    except requests.exceptions.RequestException as e:
        print(f"Error checking {url}: {e}")
        return None 

@app.route('/health-check/<province_name>')
def health_check(province_name):
    print(f"Checking health for province: {province_name}")
    province_name = province_name.replace("%20", " ")
    if province_name in entities:
        province_health_status = {}
        for service in entities[province_name]:
            result = check_health(service['url'])
            health_status = "healthy" if result else "error" if result is None else "unhealthy"
            province_health_status[service['name']] = health_status
        return jsonify({province_name: province_health_status})
    else:
        return jsonify({"error": "Province not found"}), 404

if __name__ == '__main__':
    app.run(debug=True)