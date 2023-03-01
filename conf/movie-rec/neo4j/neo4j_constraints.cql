// Constraints
CREATE CONSTRAINT constraint_movie_news IF NOT EXISTS FOR (n: `MovieNews`) REQUIRE (n.`link`, n.`pub_date`) IS KEY;
CREATE CONSTRAINT constraint_title IF NOT EXISTS FOR (n: `Title`) REQUIRE n.`tconst` IS UNIQUE;
CREATE CONSTRAINT constraint_person IF NOT EXISTS FOR (n: `Person`) REQUIRE n.`nconst` IS UNIQUE;
CREATE CONSTRAINT constraint_crew IF NOT EXISTS FOR (n: `Crew`) REQUIRE n.`tconst` IS UNIQUE;
CREATE CONSTRAINT constraint_rating IF NOT EXISTS FOR (n: `Rating`) REQUIRE n.`tconst` IS UNIQUE;

// indexes
CREATE INDEX index_movie_news_category IF NOT EXISTS FOR (n: `MovieNews`) ON (n.`category`);
CREATE INDEX index_movie_news_creator IF NOT EXISTS FOR (n: `MovieNews`) ON (n.`creator`);
CREATE INDEX index_movie_news_content IF NOT EXISTS FOR (n: `MovieNews`) ON (n.`content`);
CREATE INDEX index_movie_news_description IF NOT EXISTS FOR (n: `MovieNews`) ON (n.`description`);
CREATE INDEX index_movie_news_link IF NOT EXISTS FOR (n: `MovieNews`) ON (n.`link`);
CREATE INDEX index_movie_news_pub_date IF NOT EXISTS FOR (n: `MovieNews`) ON (n.`pub_date`);
CREATE INDEX index_movie_news_title IF NOT EXISTS FOR (n: `MovieNews`) ON (n.`title`);
CREATE INDEX index_title_primary_title IF NOT EXISTS FOR (n: `Title`) ON (n.`primaryTitle`);
CREATE INDEX index_title_original_title IF NOT EXISTS FOR (n: `Title`) ON (n.`originalTitle`);
CREATE INDEX index_title_genres IF NOT EXISTS FOR (n: `Title`) ON (n.`genres`);
CREATE INDEX index_rating_average_rating IF NOT EXISTS FOR (n: `Rating`) ON (n.`averageRating`);
CREATE INDEX index_rating_num_votes IF NOT EXISTS FOR (n: `Rating`) ON (n.`numVotes`);
CREATE INDEX index_title_runtime_minutes IF NOT EXISTS FOR (n: `Title`) ON (n.`runtimeMinutes`);
CREATE INDEX index_person_primary_name IF NOT EXISTS FOR (n: `Person`) ON (n.`primaryName`);
CREATE INDEX index_person_known_for_titles IF NOT EXISTS FOR (n: `Person`) ON (n.`knownForTitles`);
CREATE INDEX index_person_primary_profession IF NOT EXISTS FOR (n: `Person`) ON (n.`primaryProfession`);

// full_text
CREATE FULLTEXT INDEX full_text_title_primary_title FOR (n:Title) ON EACH [n.primaryTitle, n.originalTitle];
CREATE FULLTEXT INDEX full_text_person_primary_name FOR (n:Title) ON EACH [n.primaryName, n.knownForTitles];