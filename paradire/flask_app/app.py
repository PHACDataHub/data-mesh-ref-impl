from flask import Flask, render_template, jsonify

app = Flask(__name__)

entities = {
    "Federal": [
        {"name": "Kafka UI", "url": "https://kafkaui.phac.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Neo4j", "url": "https://neo4j.phac.paradire.phac-aspc.alpha.canada.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.phac.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Neodash Designer", "url": "https://neodash-designer.phac.paradire.phac-aspc.alpha.canada.ca"}
    ],
    "Alberta (AB)": [
        {"name": "Governance UI", "url": "https://governance.ab.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Patient Browser", "url": "https://patient-browser.ab.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "HAPI FHIR Server", "url": "https://fhir.ab.paradire.phac-aspc.alpha.canada.ca/fhir"},
        {"name": "Neo4j", "url": "https://neo4j.ab.paradire.phac-aspc.alpha.canada.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.ab.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Kafka UI", "url": "https://kafkaui.ab.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Neodash Designer", "url": "https://neodash-designer.ab.paradire.phac-aspc.alpha.canada.ca"}
    ],
    "British Columbia (BC)": [
        {"name": "Governance UI", "url": "https://governance.bc.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Patient Browser", "url": "https://patient-browser.bc.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "HAPI FHIR Server", "url": "https://fhir.bc.paradire.phac-aspc.alpha.canada.ca/fhir"},
        {"name": "Neo4j", "url": "https://neo4j.bc.paradire.phac-aspc.alpha.canada.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.bc.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Kafka UI", "url": "https://kafkaui.bc.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Neodash Designer", "url": "https://neodash-designer.bc.paradire.phac-aspc.alpha.canada.ca"}
    ],
    "Manitoba (MB)": [
        {"name": "Governance UI", "url": "https://governance.mb.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Patient Browser", "url": "https://patient-browser.mb.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "HAPI FHIR Server", "url": "https://fhir.mb.paradire.phac-aspc.alpha.canada.ca/fhir"},
        {"name": "Neo4j", "url": "https://neo4j.mb.paradire.phac-aspc.alpha.canada.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.mb.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Kafka UI", "url": "https://kafkaui.mb.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Neodash Designer", "url": "https://neodash-designer.mb.paradire.phac-aspc.alpha.canada.ca"}
    ],
    "New Brunswick (NB)": [
        {"name": "Governance UI", "url": "https://governance.nb.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Patient Browser", "url": "https://patient-browser.nb.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "HAPI FHIR Server", "url": "https://fhir.nb.paradire.phac-aspc.alpha.canada.ca/fhir"},
        {"name": "Neo4j", "url": "https://neo4j.nb.paradire.phac-aspc.alpha.canada.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.nb.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Kafka UI", "url": "https://kafkaui.nb.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Neodash Designer", "url": "https://neodash-designer.nb.paradire.phac-aspc.alpha.canada.ca"}
    ],
    "Newfoundland and Labrador (NL)": [
        {"name": "Governance UI", "url": "https://governance.nl.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Patient Browser", "url": "https://patient-browser.nl.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "HAPI FHIR Server", "url": "https://fhir.nl.paradire.phac-aspc.alpha.canada.ca/fhir"},
        {"name": "Neo4j", "url": "https://neo4j.nl.paradire.phac-aspc.alpha.canada.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.nl.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Kafka UI", "url": "https://kafkaui.nl.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Neodash Designer", "url": "https://neodash-designer.nl.paradire.phac-aspc.alpha.canada.ca"}
    ],
    "Nova Scotia (NS)": [
        {"name": "Governance UI", "url": "https://governance.ns.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Patient Browser", "url": "https://patient-browser.ns.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "HAPI FHIR Server", "url": "https://fhir.ns.paradire.phac-aspc.alpha.canada.ca/fhir"},
        {"name": "Neo4j", "url": "https://neo4j.ns.paradire.phac-aspc.alpha.canada.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.ns.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Kafka UI", "url": "https://kafkaui.ns.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Neodash Designer", "url": "https://neodash-designer.ns.paradire.phac-aspc.alpha.canada.ca"}
    ],
    "Nunavut (NU)": [
        {"name": "Governance UI", "url": "https://governance.nu.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Patient Browser", "url": "https://patient-browser.nu.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "HAPI FHIR Server", "url": "https://fhir.nu.paradire.phac-aspc.alpha.canada.ca/fhir"},
        {"name": "Neo4j", "url": "https://neo4j.nu.paradire.phac-aspc.alpha.canada.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.nu.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Kafka UI", "url": "https://kafkaui.nu.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Neodash Designer", "url": "https://neodash-designer.nu.paradire.phac-aspc.alpha.canada.ca"}
    ],
    "Northwest Territories (NT)": [
        {"name": "Governance UI", "url": "https://governance.nt.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Patient Browser", "url": "https://patient-browser.nt.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "HAPI FHIR Server", "url": "https://fhir.nt.paradire.phac-aspc.alpha.canada.ca/fhir"},
        {"name": "Neo4j", "url": "https://neo4j.nt.paradire.phac-aspc.alpha.canada.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.nt.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Kafka UI", "url": "https://kafkaui.nt.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Neodash Designer", "url": "https://neodash-designer.nt.paradire.phac-aspc.alpha.canada.ca"}
    ],
    "Ontario (ON)": [
        {"name": "Governance UI", "url": "https://governance.on.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Patient Browser", "url": "https://patient-browser.on.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "HAPI FHIR Server", "url": "https://fhir.on.paradire.phac-aspc.alpha.canada.ca/fhir"},
        {"name": "Neo4j", "url": "https://neo4j.on.paradire.phac-aspc.alpha.canada.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.on.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Kafka UI", "url": "https://kafkaui.on.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Neodash Designer", "url": "https://neodash-designer.on.paradire.phac-aspc.alpha.canada.ca"}
    ],
    "Prince Edward Island (PE)": [
        {"name": "Governance UI", "url": "https://governance.pe.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Patient Browser", "url": "https://patient-browser.pe.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "HAPI FHIR Server", "url": "https://fhir.pe.paradire.phac-aspc.alpha.canada.ca/fhir"},
        {"name": "Neo4j", "url": "https://neo4j.pe.paradire.phac-aspc.alpha.canada.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.pe.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Kafka UI", "url": "https://kafkaui.pe.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Neodash Designer", "url": "https://neodash-designer.pe.paradire.phac-aspc.alpha.canada.ca"}
    ],
    "Quebec (QC)": [
        {"name": "Governance UI", "url": "https://governance.qc.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Patient Browser", "url": "https://patient-browser.qc.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "HAPI FHIR Server", "url": "https://fhir.qc.paradire.phac-aspc.alpha.canada.ca/fhir"},
        {"name": "Neo4j", "url": "https://neo4j.qc.paradire.phac-aspc.alpha.canada.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.qc.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Kafka UI", "url": "https://kafkaui.qc.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Neodash Designer", "url": "https://neodash-designer.qc.paradire.phac-aspc.alpha.canada.ca"}
    ],
    "Saskatchewan (SK)": [
        {"name": "Governance UI", "url": "https://governance.sk.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Patient Browser", "url": "https://patient-browser.sk.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "HAPI FHIR Server", "url": "https://fhir.sk.paradire.phac-aspc.alpha.canada.ca/fhir"},
        {"name": "Neo4j", "url": "https://neo4j.sk.paradire.phac-aspc.alpha.canada.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.sk.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Kafka UI", "url": "https://kafkaui.sk.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Neodash Designer", "url": "https://neodash-designer.sk.paradire.phac-aspc.alpha.canada.ca"}
    ],
    "Yukon (YT)": [
        {"name": "Governance UI", "url": "https://governance.yt.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Patient Browser", "url": "https://patient-browser.yt.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "HAPI FHIR Server", "url": "https://fhir.yt.paradire.phac-aspc.alpha.canada.ca/fhir"},
        {"name": "Neo4j", "url": "https://neo4j.yt.paradire.phac-aspc.alpha.canada.ca/browser"},
        {"name": "Neodash", "url": "https://neodash.yt.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Kafka UI", "url": "https://kafkaui.yt.paradire.phac-aspc.alpha.canada.ca"},
        {"name": "Neodash Designer", "url": "https://neodash-designer.yt.paradire.phac-aspc.alpha.canada.ca"}
    ]
}

@app.route('/')
def index():
    return render_template('index.html', entities=entities)

if __name__ == '__main__':
    app.run(debug=True)