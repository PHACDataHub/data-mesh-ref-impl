/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// title.akas.tsv.gz - Contains the following information for titles:
// titleId (string) - a tconst, an alphanumeric unique identifier of the title
// ordering (integer) – a number to uniquely identify rows for a given titleId
// title (string) – the localized title
// region (string) - the region for this version of the title
// language (string) - the language of the title
// types (array) - Enumerated set of attributes for this alternative title. One or more of the following: "alternative", "dvd", "festival", "tv", "video", "working", "original", "imdbDisplay". New values may be added in the future without warning
// attributes (array) - Additional terms to describe this alternative title, not enumerated
// isOriginalTitle (boolean) – 0: not original title; 1: original title

LOAD CSV WITH HEADERS FROM "file:///title.akas.tsv" AS row FIELDTERMINATOR '\t'
CALL {
    WITH row
    MERGE (t:Title { titleId: row.titleId })
        ON CREATE SET
            t.ordering = toInteger(row.ordering),
            t.title = row.title,
            t.region = row.region,
            t.language = row.language,
            t. types = row.types,
            t.attributes = row.attributes,
            t.isOriginalTitle = CASE row.ordering WHEN '1' THEN True ELSE False;
} IN TRANSACTIONS OF 500 ROWS
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
