/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// A. Load cases, manufacturers and relate them 

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/neo4j-graph-examples/healthcare-analytics/main/data/csv/demographics.csv" AS row

//Conditionally create Case nodes, set properties on first create
MERGE (c:Case { primaryid: toInteger(row.primaryid) })
    ON CREATE SET
        c.eventDate= date(row.eventDate),
        c.reportDate= date(row.reportDate),
        c.age = toFloat(row.age),
        c.ageUnit = row.ageUnit,
        c.gender = row.sex,
        c.reporterOccupation = row.reporterOccupation

    //Conditionally create Manufacturer
    MERGE (m:Manufacturer { manufacturerName: row.manufacturerName } )

    //Relate case and manufacturer
    MERGE (m)-[:REGISTERED]->(c)

    //Conditionally create age group node and relate with case
    MERGE (a:AgeGroup { ageGroup: row.ageGroup })

    //Relate case with age group
    MERGE (c)-[:FALLS_UNDER]->(a)

    RETURN count (c);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// B. Load other information related to the events 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// B.1 Load outcomes and link them with cases 

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/neo4j-graph-examples/healthcare-analytics/main/data/csv/outcome.csv" AS row

// Conditionally create outcome node
MERGE (o:Outcome { code: row.code })
    ON CREATE SET
        o.outcome = row.outcome

WITH o, row
    
    // Find the case to relate this outcome to
    MATCH (c:Case {primaryid: toInteger(row.primaryid)})

    // Relate
    MERGE (c)-[:RESULTED_IN]->(o)

    RETURN count(o);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// B.2 Load reactions and link them with cases 

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/neo4j-graph-examples/healthcare-analytics/main/data/csv/reaction.csv" AS row

//Conditionally create reaction node
MERGE (r:Reaction { description: row.description })

WITH r, row

    //Find the case to relate this reaction to
    MATCH (c:Case {primaryid: toInteger(row.primaryid)})

    //Relate
    MERGE (c)-[:HAS_REACTION]->(r)

    RETURN count(r);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// B.3 Load report sources and link them with cases 

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/neo4j-graph-examples/healthcare-analytics/main/data/csv/reportSources.csv" AS row

// Conditionally create reportSource node
MERGE (r:ReportSource { code: row.code })
    ON CREATE SET
        r.name = row.name

WITH r, row

    // Find the case to relate this report source to
    MATCH (c:Case {primaryid: toInteger(row.primaryid) })

WITH c, r

    // Relate
    MERGE (c)-[:REPORTED_BY]->(r)

    RETURN count(r);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// C. Load drugs and therapies
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// C.1 Load drugs with indications and link them with cases using relationships based on their roles for the cases
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/neo4j-graph-examples/healthcare-analytics/main/data/csv/drugs-indication.csv" AS row

CALL { WITH row

    //Conditionally create Drug node
    MERGE (d:Drug { name: row.name })
        ON CREATE SET
            d.primarySubstabce = row.primarySubstabce

    WITH d, row

        //Find the case to relate this drug based on the suspect type
        MATCH (c:Case {primaryid: toInteger(row.primaryid)})

        FOREACH (_ IN CASE WHEN row.role = "Primary Suspect" THEN [1] ELSE [] END |
            //Relate
            MERGE (c)-[relate:IS_PRIMARY_SUSPECT { drugSequence: row.drugSequence, route: row.route, doseAmount: row.doseAmount, doseUnit: row.doseUnit, indication: row.indication  }]->(d)
        )

        FOREACH (_ IN CASE WHEN row.role = "Secondary Suspect" THEN [1] ELSE [] END |
            //Relate
            MERGE (c)-[relate:IS_SECONDARY_SUSPECT { drugSequence: row.drugSequence, route: row.route, doseAmount: row.doseAmount, doseUnit: row.doseUnit, indication: row.indication  }]->(d)
        )

        FOREACH (_ IN CASE WHEN row.role = "Concomitant" THEN [1] ELSE [] END |
            //Relate
            MERGE (c)-[relate:IS_CONCOMITANT { drugSequence: row.drugSequence, route: row.route, doseAmount: row.doseAmount, doseUnit: row.doseUnit, indication: row.indication  }]->(d)
        )

        FOREACH (_ IN CASE WHEN row.role = "Interacting" THEN [1] ELSE [] END |
            //Relate
            MERGE (c)-[relate:IS_INTERACTING { drugSequence: row.drugSequence, route: row.route, doseAmount: row.doseAmount, doseUnit: row.doseUnit, indication: row.indication  }]->(d)
        )

} IN TRANSACTIONS OF 5000 ROWS;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// C.2 Load therapies and link them with cases and drugs 

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/neo4j-graph-examples/healthcare-analytics/main/data/csv/therapy.csv" AS row

//Conditionally create therapy node
MERGE (t:Therapy { primaryid: toInteger(row.primaryid) })

WITH t, row
    
    //Find the case to relate this therapy to
    MATCH (c:Case {primaryid: toInteger(row.primaryid)})

    //Relate case with therapy
    MERGE (c)-[:RECEIVED]->(t)

WITH c, t, row

    //Find drugs prescribed in the therapy
    MATCH (d:Drug { name: row.drugName })

    //Relate therapy and drugs
    MERGE (t)-[:PRESCRIBED { drugSequence: row.drugSequence, startYear: coalesce(row.startYear, 1900), endYear: coalesce(row.endYear, 2021) } ]->(d);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////