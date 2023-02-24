// Constraints
CREATE CONSTRAINT constraint_movie_news IF NOT EXISTS FOR (n: `MovieNews`) REQUIRE (n.`link`, n.`pub_date`) IS KEY;
CREATE CONSTRAINT constraint_title IF NOT EXISTS FOR (n: `Title`) REQUIRE n.`titleId` IS UNIQUE;
CREATE CONSTRAINT constraint_local_title IF NOT EXISTS FOR (n: `LocalTitle`) REQUIRE (n.`titleId`, n.`ordering`) IS KEY;
CREATE CONSTRAINT constraint_epizode IF NOT EXISTS FOR (n: `Epizode`) REQUIRE (n.`titleId`, n.`tconst`) IS KEY;
CREATE CONSTRAINT constraint_person IF NOT EXISTS FOR (n: `Person`) REQUIRE n.`nconst` IS UNIQUE;
CREATE CONSTRAINT constraint_role IF NOT EXISTS FOR (n: `Role`) REQUIRE (n.`titleId`, n.`ordering`, n.`nconst`) IS KEY;

// indexes
CREATE INDEX index_movie_news_category IF NOT EXISTS FOR (n: `MovieNews`) ON (n.`category`);
CREATE INDEX index_movie_news_creator IF NOT EXISTS FOR (n: `MovieNews`) ON (n.`creator`);
CREATE INDEX index_movie_news_content IF NOT EXISTS FOR (n: `MovieNews`) ON (n.`content`);
CREATE INDEX index_movie_news_description IF NOT EXISTS FOR (n: `MovieNews`) ON (n.`description`);
CREATE INDEX index_movie_news_link IF NOT EXISTS FOR (n: `MovieNews`) ON (n.`link`);
CREATE INDEX index_movie_news_pub_date IF NOT EXISTS FOR (n: `MovieNews`) ON (n.`pub_date`);
CREATE INDEX index_movie_news_title IF NOT EXISTS FOR (n: `MovieNews`) ON (n.`title`);
CREATE INDEX index_local_title IF NOT EXISTS FOR (n: `LocalTitle`) ON (n.`titleId`);
CREATE INDEX index_title_primary_title IF NOT EXISTS FOR (n: `Title`) ON (n.`primaryTitle`);
CREATE INDEX index_title_original_title IF NOT EXISTS FOR (n: `Title`) ON (n.`originalTitle`);
CREATE INDEX index_title_genres IF NOT EXISTS FOR (n: `Title`) ON (n.`genres`);
CREATE INDEX index_title_average_rating IF NOT EXISTS FOR (n: `Title`) ON (n.`averageRating`);
CREATE INDEX index_title_num_votes IF NOT EXISTS FOR (n: `Title`) ON (n.`numVotes`);
CREATE INDEX index_title_runtime_minutes IF NOT EXISTS FOR (n: `Title`) ON (n.`runtimeMinutes`);
CREATE INDEX index_person_primary_name IF NOT EXISTS FOR (n: `Person`) ON (n.`primaryName`);
CREATE INDEX index_person_known_for_titles IF NOT EXISTS FOR (n: `Person`) ON (n.`knownForTitles`);
CREATE INDEX index_person_primary_profession IF NOT EXISTS FOR (n: `Person`) ON (n.`primaryProfession`);
