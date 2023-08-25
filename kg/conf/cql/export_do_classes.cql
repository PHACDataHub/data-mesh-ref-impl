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
        url, apoc.text.join(labels + textual_definitions + synonyms,'\\\\n\\\\n') AS cnt"
    AS query
CALL apoc.export.csv.query(query, "do-classes.csv")
YIELD file, source, format, nodes, relationships, properties, time, rows, batchSize, batches, done, data
RETURN file, source, format, nodes, relationships, properties, time, rows, batchSize, batches, done, data;

//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
