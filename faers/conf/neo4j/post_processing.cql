/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// A. Load cases, manufacturers and relate them 
//
CALL apoc.periodic.iterate("
    MATCH (n:demo)
    RETURN n
","
    WITH n
        MERGE (c:Case { primaryid: n.primaryid })
            ON CREATE SET
                c.eventDate = n.event_dt,
                c.reportDate = n.rept_dt,
                c.age = toFloat(n.age),
                c.ageUnit = n.age_cod,
                c.gender = n.sex,
                c.reporterOccupation = n.occp_cod

        //Conditionally create Manufacturer and relate to case
        FOREACH (_ IN CASE SIZE(n.mfr_sndr) > 0 WHEN true THEN [1] ELSE [] END |
            MERGE (m:Manufacturer { manufacturerName: n.mfr_sndr } )
            MERGE (m)-[:REGISTERED]->(c)
        )

        //Conditionally create age group node and relate to case
        FOREACH (_ IN CASE SIZE(n.age_grp) > 0 WHEN true THEN [1] ELSE [] END |
            MERGE (a:AgeGroup { ageGroup: n.age_grp })
            MERGE (c)-[:FALLS_UNDER]->(a)
        )
    RETURN COUNT(c);
",
    {batchSize:1000, parallel:false}
);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// B. Load other information related to the events 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// B.1 Load outcomes and link them with cases 
//
CALL apoc.periodic.iterate("
    MATCH (n:outc)
    RETURN n
","
    WITH n
        MERGE (o:Outcome { code: n.outc_cod })
            ON CREATE SET
                o.outcome = CASE n.outc_cod
                    WHEN 'DE' THEN 'Death'
                    WHEN 'LT' THEN 'Life-Threatening'
                    WHEN 'HO' THEN 'Hospitalization - Initial or Prolonged'
                    WHEN 'DS' THEN 'Disability'
                    WHEN 'CA' THEN 'Congenital Anomaly'
                    WHEN 'RI' THEN 'Required Intervention to Prevent Permanent Impairment/Damage'
                    WHEN 'OT' THEN 'Other Serious (Important Medical Event)'
                    ELSE 'Unknown'
                END
    WITH o, n
        // Find the case to relate this outcome to
        MATCH (c:Case {primaryid: n.primaryid})
        MERGE (c)-[:RESULTED_IN]->(o)
    RETURN COUNT(o);
",
    {batchSize:1000, parallel:false}
);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// B.2 Load reactions and link them with cases 
//
CALL apoc.periodic.iterate("
    MATCH (n:reac)
    RETURN n
","
    WITH n
        MERGE (r:Reaction { description: n.pt })
    WITH r, n
        //Find the case to relate this reaction to
        MATCH (c:Case {primaryid: n.primaryid})
        MERGE (c)-[:HAS_REACTION]->(r)
    RETURN count(r);
",
    {batchSize:1000, parallel:false}
);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// B.3 Load report sources and link them with cases 
//
CALL apoc.periodic.iterate("
    MATCH (n:rpsr)
    RETURN n
","
    WITH n
        MERGE (r:ReportSource { code: n.rpsr_cod })
            ON CREATE SET
                r.name = CASE n.rpsr_cod
                    WHEN 'FGN' THEN 'Foreign'
                    WHEN 'SDY' THEN 'Study'
                    WHEN 'LIT' THEN 'Literature'
                    WHEN 'CSM' THEN 'Consumer'
                    WHEN 'HP' THEN 'Health Professional'
                    WHEN 'UF' THEN 'User Facility'
                    WHEN 'CR' THEN 'Company Representative'
                    WHEN 'DT' THEN 'Distributor'
                    WHEN 'OTH' THEN 'Other'
                    ELSE 'Unknown'
                END
    WITH r, n
        // Find the case to relate this report source to
        MATCH (c:Case {primaryid: n.primaryid })
        MERGE (c)-[:REPORTED_BY]->(r)
    RETURN count(r);
",
    {batchSize:1000, parallel:false}
);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// C. Load drugs and therapies
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// C.1 Load drugs with indications and link them with cases using relationships based on their roles for the cases
//
CALL apoc.periodic.iterate("
    MATCH (n:drug)
    WITH n
        OPTIONAL MATCH (i:indi {primaryid: n.primaryid, indi_drug_seq: n.drug_seq})
    RETURN n, i, 
        CASE i.indi_pt IS NOT NULL WHEN true THEN i.indi_pt  ELSE '' END AS indication,
        CASE n.val_vbm WHEN '1' THEN n.drugname ELSE n.dose_vbm END AS drugname
","
    WITH n, i, indication, drugname
        MERGE (d:Drug { name: drugname })
            ON CREATE SET
                d.primarySubstabce = n.prod_ai
    WITH drugname, indication, d, i, n
        //Find the case to relate this drug based on the suspect type
        MATCH (c:Case {primaryid: n.primaryid})
        FOREACH (_ IN CASE WHEN n.role_cod = 'PS' THEN [1] ELSE [] END |
            MERGE (c)-[relate:IS_PRIMARY_SUSPECT { 
                drugSequence: n.drug_seq, route: n.route, doseAmount: n.dose_amt, doseUnit: n.dose_unit, indication: indication
            }]->(d)
        )
        FOREACH (_ IN CASE WHEN n.role_cod = 'SS' THEN [1] ELSE [] END |
            MERGE (c)-[relate:IS_SECONDARY_SUSPECT { 
                drugSequence: n.drug_seq, route: n.route, doseAmount: n.dose_amt, doseUnit: n.dose_unit, indication: indication
            }]->(d)
        )
        FOREACH (_ IN CASE WHEN n.role_cod = 'C' THEN [1] ELSE [] END |
            MERGE (c)-[relate:IS_CONCOMITANT { 
                drugSequence: n.drug_seq, route: n.route, doseAmount: n.dose_amt, doseUnit: n.dose_unit, indication: indication
            }]->(d)
        )
        FOREACH (_ IN CASE WHEN n.role_cod = 'I' THEN [1] ELSE [] END |
            MERGE (c)-[relate:IS_INTERACTING { 
                drugSequence: n.drug_seq, route: n.route, doseAmount: n.dose_amt, doseUnit: n.dose_unit, indication: indication
            }]->(d)
        )
",
    {batchSize:1000, parallel:false}
);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// C.2 Load therapies and link them with cases and drugs 
//
CALL apoc.periodic.iterate("
    MATCH (n:ther)
    WITH n
        MATCH (d:drug {primaryid: n.primaryid, drug_seq: n.dsg_drug_seq})
    RETURN n, d.drugname AS drugname
","
    WITH n, drugname
        //Conditionally create therapy node
        MERGE (t:Therapy { primaryid: n.primaryid })
    WITH t, n, drugname
        //Find the case to relate this therapy to
        MATCH (c:Case {primaryid: n.primaryid})
        MERGE (c)-[:RECEIVED]->(t)
    WITH c, t, n, drugname,
        CASE SIZE(n.start_dt) >= 4 WHEN true THEN SUBSTRING(n.start_dt, 0, 4) ELSE '1900' END AS startYear,
        CASE SIZE(n.end_dt) >= 4 WHEN true THEN SUBSTRING(n.end_dt, 0, 4) ELSE '2022' END AS endYear
        //Find drugs prescribed in the therapy
        MATCH (d:Drug { name: drugname })
        MERGE (t)-[:PRESCRIBED { drugSequence: n.dsg_drug_seq, startYear: startYear, endYear: endYear } ]->(d);
",
    {batchSize:1000, parallel:false}
);
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////