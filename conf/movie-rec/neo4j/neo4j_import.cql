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
    MATCH (t:Title)
    RETURN t
","
    WITH t
        SET t.tconst = t.tconst;
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
    MATCH (r:Rating)
    RETURN r
","
    WITH r
        SET r.tconst = r.tconst;
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
    MATCH (c:Crew)
    RETURN c
","
    WITH c
        SET c.tconst = c.tconst;
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
    MATCH (p:Person)
    RETURN p
","
    WITH p
        SET p.nconst = p.nconst;
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
    MATCH (r:Rating)
    RETURN r
","
    WITH r
    MERGE (t:Title {tconst: r.tconst})
        SET
            t.averageRating = toFloatOrNull(r.averageRating),
            t.numVotes = toIntegerOrNull(r.numVotes);
",
    {batchSize:100, parallel:true}
);
//
CALL apoc.periodic.iterate("
    MATCH (r:Rating)
    RETURN r
","
    WITH r
    DELETE r;
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
    MATCH (c:Crew)
    RETURN c
","
    WITH c
    MERGE (t:Title {tconst: c.tconst})
        SET
            t.directors = c.directors,
            t.writers = c.writers;
",
    {batchSize:100, parallel:true}
);
//
CALL apoc.periodic.iterate("
    MATCH (c:Crew)
    RETURN c
","
    WITH c
    DELETE c;
",
    {batchSize:100, parallel:true}
);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
