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
// Creating constraint for Biomedical & Clinical NER Models
CREATE CONSTRAINT anatem_radiology_text IF NOT EXISTS FOR (n: `ANATOMY`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT bc5cdr_bc4chemd_text IF NOT EXISTS FOR (n: `CHEMICAL`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT bc5cdr_ncbi_text IF NOT EXISTS FOR (n: `DISEASE`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT protein_text IF NOT EXISTS FOR (n: `PROTEIN`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT dna_text IF NOT EXISTS FOR (n: `DNA`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT rna_text IF NOT EXISTS FOR (n: `RNA`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT cell_line_text IF NOT EXISTS FOR (n: `CELL_LINE`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT cell_type_text IF NOT EXISTS FOR (n: `CELL_TYPE`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT linnaeus_s800_text IF NOT EXISTS FOR (n: `SPECIES`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT problem_text IF NOT EXISTS FOR (n: `PROBLEM`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT test_text IF NOT EXISTS FOR (n: `TEST`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT treatment_text IF NOT EXISTS FOR (n: `TREATMENT`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT observation_text IF NOT EXISTS FOR (n: `OBSERVATION`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT anatomy_modifier_text IF NOT EXISTS FOR (n: `ANATOMY_MODIFIER`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT observation_modifier_text IF NOT EXISTS FOR (n: `OBSERVATION_MODIFIER`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT uncertainty_text IF NOT EXISTS FOR (n: `UNCERTAINTY`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT amino_acid_text IF NOT EXISTS FOR (n: `AMINO_ACID`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT anatomical_system_text IF NOT EXISTS FOR (n: `ANATOMICAL_SYSTEM`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT cancer_text IF NOT EXISTS FOR (n: `CANCER`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT cell_text IF NOT EXISTS FOR (n: `CELL`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT cellular_component_text IF NOT EXISTS FOR (n: `CELLULAR_COMPONENT`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT developing_anatomical_structure_text IF NOT EXISTS FOR (n: `DEVELOPING_ANATOMICAL_STRUCTURE`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT gene_or_gene_product_text IF NOT EXISTS FOR (n: `GENE_OR_GENE_PRODUCT`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT immaterial_anatomical_entity_text IF NOT EXISTS FOR (n: `IMMATERIAL_ANATOMICAL_ENTITY`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT multi_tissue_structure_text IF NOT EXISTS FOR (n: `MULTI_TISSUE_STRUCTURE`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT organ_text IF NOT EXISTS FOR (n: `ORGAN`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT organism_text IF NOT EXISTS FOR (n: `ORGANISM`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT organism_subdivision_text IF NOT EXISTS FOR (n: `ORGANISM_SUBDIVISION`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT organism_substance_text IF NOT EXISTS FOR (n: `ORGANISM_SUBSTANCE`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT pathological_formation_text IF NOT EXISTS FOR (n: `PATHOLOGICAL_FORMATION`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT simple_chemical_text IF NOT EXISTS FOR (n: `SIMPLE_CHEMICAL`) REQUIRE n.`text` IS UNIQUE;
CREATE CONSTRAINT tissue_text IF NOT EXISTS FOR (n: `TISSUE`) REQUIRE n.`text` IS UNIQUE;
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

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
WITH 
    "MATCH (r:Resource:owl__Class)
        WHERE r.rdfs__label IS NOT NULL OR r.obo__IAO_0000115 IS NOT NULL OR r.oboInOwl__hasExactSynonym IS NOT NULL
    WITH 
        r.uri AS url, 
        r.rdfs__label AS labels,
        CASE WHEN r.obo__IAO_0000115 IS NOT NULL THEN r.obo__IAO_0000115 ELSE [] END AS textual_definitions,
        CASE WHEN r.oboInOwl__hasExactSynonym IS NOT NULL THEN r.oboInOwl__hasExactSynonym ELSE [] END AS synonyms
    RETURN
        url, apoc.text.join(labels + synonyms,'\\\\n\\\\n') AS cnt"
    AS query
CALL apoc.export.csv.query(query, "do-classes.csv", {})
YIELD file, source, format, nodes, relationships, properties, time, rows, batchSize, batches, done, data
RETURN file, source, format, nodes, relationships, properties, time, rows, batchSize, batches, done, data;
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
