/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// title.akas.tsv - Contains the following information for titles:
// - titleId (string) - a tconst, an alphanumeric unique identifier of the title
// - ordering (integer) – a number to uniquely identify rows for a given titleId
// - title (string) – the localized title
// - region (string) - the region for this version of the title
// - language (string) - the language of the title
// - types (array) - Enumerated set of attributes for this alternative title. One or more of the following: "alternative", "dvd", "festival", "tv", "video", "working", "original", "imdbDisplay". New values may be added in the future without warning
// - attributes (array) - Additional terms to describe this alternative title, not enumerated
// - isOriginalTitle (boolean) – 0: not original title; 1: original title
//
CALL apoc.periodic.iterate("
    CALL apoc.load.csv('file:///title.akas.tsv', {sep:'TAB'})
        YIELD lineNo, map, list
    RETURN map AS row
","
    WITH row
    MERGE (t:LocalTitle { titleId: row.titleId, ordering: toInteger(row.ordering) })
        SET
            t.title = row.title,
            t.region = row.region,
            t.language = row.language,
            t.types = row.types,
            t.attributes = row.attributes,
            t.isOriginalTitle = CASE row.isOriginalTitle WHEN '1' THEN True ELSE False END;
",
    {batchSize:100, parallel:true}
);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// title.basics.tsv - Contains the following information for titles:
// - tconst (string) - alphanumeric unique identifier of the title
// - titleType (string) – the type/format of the title (e.g. movie, short, tvseries, tvepisode, video, etc)
// - primaryTitle (string) – the more popular title / the title used by the filmmakers on promotional materials at the point of release
// - originalTitle (string) - original title, in the original language
// - isAdult (boolean) - 0: non-adult title; 1: adult title
// - startYear (YYYY) – represents the release year of a title. In the case of TV Series, it is the series start year
// - endYear (YYYY) – TV Series end year. ‘\N’ for all other title types
// - runtimeMinutes – primary runtime of the title, in minutes
// - genres (string array) – includes up to three genres associated with the title
//
CALL apoc.periodic.iterate("
    CALL apoc.load.csv('file:///title.basics.tsv', {sep:'TAB'})
        YIELD lineNo, map, list
    RETURN map AS row
","
    WITH row
    MERGE (t:Title { titleId: row.tconst })
        SET
            t.titleType = row.titleType,
            t.primaryTitle = row.primaryTitle,
            t.originalTitle = row.originalTitle,
            t.isAdult = CASE row.isAdult WHEN '1' THEN True ELSE False END,
            t.startYear = toInteger(row.startYear),
            t.endYear = toInteger(row.endYear),
            t.runtimeMinutes = toInteger(row.runtimeMinutes),
            t.genres = row.genres;
            
",
    {batchSize:100, parallel:true}
);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// title.crew.tsv - Contains the director and writer information for all the titles in IMDb. Fields include:
// - tconst (string) - alphanumeric unique identifier of the title
// - directors (array of nconsts) - director(s) of the given title
// - writers (array of nconsts) – writer(s) of the given title
//
CALL apoc.periodic.iterate("
    CALL apoc.load.csv('file:///title.crew.tsv', {sep:'TAB'})
        YIELD lineNo, map, list
    RETURN map AS row
","
    WITH row
    MERGE (t:Title { titleId: row.tconst })
        SET
            t.directors = row.directors,
            t.writers = row.writers;
            
",
    {batchSize:100, parallel:true}
);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// title.episode.tsv – Contains the tv episode information. Fields include:
// - tconst (string) - alphanumeric identifier of episode
// - parentTconst (string) - alphanumeric identifier of the parent TV Series
// - seasonNumber (integer) – season number the episode belongs to
// - episodeNumber (integer) – episode number of the tconst in the TV series
//
CALL apoc.periodic.iterate("
    CALL apoc.load.csv('file:///title.episode.tsv', {sep:'TAB'})
        YIELD lineNo, map, list
    RETURN map AS row
","
    WITH row
    MERGE (e:Epizode { titleId: row.parentTconst, tconst: row.tconst })
        SET
            e.seasonNumber = toInteger(row.seasonNumber),
            e.episodeNumber = toInteger(row.episodeNumber);
            
",
    {batchSize:100, parallel:true}
);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// title.ratings.tsv – Contains the IMDb rating and votes information for titles
// - tconst (string) - alphanumeric unique identifier of the title
// - averageRating – weighted average of all the individual user ratings
// - numVotes - number of votes the title has received
//
CALL apoc.periodic.iterate("
    CALL apoc.load.csv('file:///title.ratings.tsv', {sep:'TAB'})
        YIELD lineNo, map, list
    RETURN map AS row
","
    WITH row
    MERGE (t:Title { titleId: row.tconst })
        SET
            t.numVotes = toFloatOrNull(row.averageRating),
            t.numVotes = toIntegerOrNull(row.numVotes);
            
",
    {batchSize:100, parallel:true}
);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// name.basics.tsv - Contains the following information for names:
// - nconst (string) - alphanumeric unique identifier of the name/person
// - primaryName (string)– name by which the person is most often credited
// - birthYear – in YYYY format
// - deathYear – in YYYY format if applicable, else '\N'
// - primaryProfession (array of strings)– the top-3 professions of the person
// - knownForTitles (array of tconsts) – titles the person is known for
//
CALL apoc.periodic.iterate("
    CALL apoc.load.csv('file:///name.basics.tsv', {sep:'TAB'})
        YIELD lineNo, map, list
    RETURN map AS row
","
    WITH row
    MERGE (p:Person { nconst: row.nconst })
        SET
            p.primaryName = row.primaryName,
            p.birthYear = toIntegerOrNull(row.birthYear),
            p.deathYear = toIntegerOrNull(row.deathYear),
            p.primaryProfession = row.primaryProfession,
            p.knownForTitles = row.knownForTitles;
",
    {batchSize:100, parallel:true}
);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// title.principals.tsv – Contains the principal cast/crew for titles
// - tconst (string) - alphanumeric unique identifier of the title
// - ordering (integer) – a number to uniquely identify rows for a given titleId
// - nconst (string) - alphanumeric unique identifier of the name/person
// - category (string) - the category of job that person was in
// - job (string) - the specific job title if applicable, else '\N'
// - characters (string) - the name of the character played if applicable, else '\N'
//
CALL apoc.periodic.iterate("
    CALL apoc.load.csv('file:///title.principals.tsv', {sep:'TAB'})
        YIELD lineNo, map, list
    RETURN map AS row
","
    WITH row
    MERGE (n:Role { titleId: row.tconst, ordering: toInteger(row.ordering), nconst: row.nconst })
        SET
            n.category = row.category,
            n.job = row.job,
            n.characters = row.characters;
",
    {batchSize:100, parallel:true}
);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
