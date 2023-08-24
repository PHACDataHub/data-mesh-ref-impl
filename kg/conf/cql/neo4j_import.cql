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
