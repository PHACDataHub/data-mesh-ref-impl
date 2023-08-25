/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Creating constraints for named entities
CREATE CONSTRAINT cause_of_death_text IF NOT EXISTS FOR (n: `CAUSE_OF_DEATH`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT city_text IF NOT EXISTS FOR (n: `CITY`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT country_text IF NOT EXISTS FOR (n: `COUNTRY`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT crime_charge_text IF NOT EXISTS FOR (n: `CRIME_CHARGE`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT date_text IF NOT EXISTS FOR (n: `DATE`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT duration_text IF NOT EXISTS FOR (n: `DURATION`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT email_text IF NOT EXISTS FOR (n: `EMAIL`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT handle_text IF NOT EXISTS FOR (n: `HANDLE`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT ideology_text IF NOT EXISTS FOR (n: `IDEOLOGY`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT location_text IF NOT EXISTS FOR (n: `LOCATION`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT misc_text IF NOT EXISTS FOR (n: `MISC`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT money_text IF NOT EXISTS FOR (n: `MONEY`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT nationality_text IF NOT EXISTS FOR (n: `NATIONALITY`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT number_text IF NOT EXISTS FOR (n: `NUMBER`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT ordinal_text IF NOT EXISTS FOR (n: `ORDINAL`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT organization_text IF NOT EXISTS FOR (n: `ORGANIZATION`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT percent_text IF NOT EXISTS FOR (n: `PERCENT`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT person_text IF NOT EXISTS FOR (n: `PERSON`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT religion_text IF NOT EXISTS FOR (n: `RELIGION`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT set_text IF NOT EXISTS FOR (n: `SET`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT state_or_province_text IF NOT EXISTS FOR (n: `STATE_OR_PROVINCE`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT time_text IF NOT EXISTS FOR (n: `TIME`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT title_text IF NOT EXISTS FOR (n: `TITLE`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT url_text IF NOT EXISTS FOR (n: `URL`) REQUIRE n.`text` IS UNIQUE;
//
// Creating constraint for key phrases
CREATE CONSTRAINT KP_text IF NOT EXISTS FOR (n: `KP`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT W_text IF NOT EXISTS FOR (n: `W`) REQUIRE n.`text` IS UNIQUE;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Setting the configuration of the graph
CALL n10s.graphconfig.init({  handleMultival: "ARRAY" });
//
// Create unique constraint
CREATE CONSTRAINT n10s_unique_uri IF NOT EXISTS FOR (r:Resource) REQUIRE r.uri IS UNIQUE;

// Add namespaces and prefixes
WITH '<rdf:RDF xmlns="http://purl.obolibrary.org/obo/doid.owl#"
     xml:base="http://purl.obolibrary.org/obo/doid.owl"
     xmlns:dc="http://purl.org/dc/elements/1.1/"
     xmlns:obo="http://purl.obolibrary.org/obo/"
     xmlns:owl="http://www.w3.org/2002/07/owl#"
     xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
     xmlns:xml="http://www.w3.org/XML/1998/namespace"
     xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
     xmlns:doid="http://purl.obolibrary.org/obo/doid#"
     xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
     xmlns:skos="http://www.w3.org/2004/02/skos/core#"
     xmlns:terms="http://purl.org/dc/terms/"
     xmlns:oboInOwl="http://www.geneontology.org/formats/oboInOwl#"' AS text
    CALL n10s.nsprefixes.addFromText(text) yield prefix, namespace
RETURN prefix, namespace;
//
// Import Disease Ontology
CALL n10s.rdf.import.fetch("https://raw.githubusercontent.com/DiseaseOntology/HumanDiseaseOntology/main/src/ontology/doid.owl", "RDF/XML");
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
