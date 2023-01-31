// Constraints
CREATE CONSTRAINT constraint_drug_name IF NOT EXISTS FOR (n: `Drug`) REQUIRE n.`name` IS UNIQUE;
CREATE CONSTRAINT constraint_case_primaryid IF NOT EXISTS FOR (n: `Case`) REQUIRE n.`primaryid` IS UNIQUE;
CREATE CONSTRAINT constraint_reaction_description IF NOT EXISTS FOR (n: `Reaction`) REQUIRE n.`description` IS UNIQUE;
CREATE CONSTRAINT constraint_reportsource_code IF NOT EXISTS FOR (n: `ReportSource`) REQUIRE n.`code` IS UNIQUE;
CREATE CONSTRAINT constraint_outcome_code IF NOT EXISTS FOR (n: `Outcome`) REQUIRE n.`code` IS UNIQUE;
CREATE CONSTRAINT constraint_therapy_primaryid IF NOT EXISTS FOR (n: `Therapy`) REQUIRE n.`primaryid` IS UNIQUE;
CREATE CONSTRAINT constraint_manufacturer_name IF NOT EXISTS FOR (n: `Manufacturer`) REQUIRE n.`manufacturerName` IS UNIQUE;

// indexes
CREATE INDEX index_case_age IF NOT EXISTS FOR (n: `Case`) ON (n.`age`);
CREATE INDEX index_case_ageUnit IF NOT EXISTS FOR (n: `Case`) ON (n.`ageUnit`);
CREATE INDEX index_case_gender IF NOT EXISTS FOR (n: `Case`) ON (n.`gender`);
CREATE INDEX index_case_eventdate IF NOT EXISTS FOR (n: `Case`) ON (n.`eventDate`);
CREATE INDEX index_case_reportdate IF NOT EXISTS FOR (n: `Case`) ON (n.`reportDate`);
