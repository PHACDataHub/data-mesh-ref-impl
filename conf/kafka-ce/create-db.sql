DROP DATABASE IF EXISTS geo;
CREATE DATABASE geo;

USE geo;

CREATE TABLE counties (
    county VARCHAR(255),
    county_ascii VARCHAR(255),
    county_full VARCHAR(255),
    county_fips VARCHAR(255),
    state_id VARCHAR(255),
    state_name VARCHAR(255),
    lat FLOAT(7,4),
    lng FLOAT(7,4),
    population INT
);

INSERT INTO counties (county,county_ascii,county_full,county_fips,state_id,state_name,lat,lng,population) VALUE("Los Angeles","Los Angeles","Los Angeles County","06037","CA","California",34.3209,-118.2247,10040682);
INSERT INTO counties (county,county_ascii,county_full,county_fips,state_id,state_name,lat,lng,population) VALUE("Cook","Cook","Cook County","17031","IL","Illinois",41.8401,-87.8168,5169517);
INSERT INTO counties (county,county_ascii,county_full,county_fips,state_id,state_name,lat,lng,population) VALUE("Harris","Harris","Harris County","48201","TX","Texas",29.8578,-95.3936,4680);
INSERT INTO counties (county,county_ascii,county_full,county_fips,state_id,state_name,lat,lng,population) VALUE("Maricopa","Maricopa","Maricopa County","04013","AZ","Arizona",33.3490,-112.4915,4412779);
INSERT INTO counties (county,county_ascii,county_full,county_fips,state_id,state_name,lat,lng,population) VALUE("San Diego","San Diego","San Diego County","06073","CA","California",33.0343,-116.7350,3323970);
INSERT INTO counties (county,county_ascii,county_full,county_fips,state_id,state_name,lat,lng,population) VALUE("Orange","Orange","Orange County","06059","CA","California",33.7031,-117.7609,3170345);
INSERT INTO counties (county,county_ascii,county_full,county_fips,state_id,state_name,lat,lng,population) VALUE("Miami-Dade","Miami-Dade","Miami-Dade County","12086","FL","Florida",25.6149,-80.5623,2705528);
INSERT INTO counties (county,county_ascii,county_full,county_fips,state_id,state_name,lat,lng,population) VALUE("Dallas","Dallas","Dallas County","48113","TX","Texas",32.7666,-96.7778,2622634);
INSERT INTO counties (county,county_ascii,county_full,county_fips,state_id,state_name,lat,lng,population) VALUE("Kings","Kings","Kings County","36047","NY","New York",40.6395,-73.9385,2576771);
INSERT INTO counties (county,county_ascii,county_full,county_fips,state_id,state_name,lat,lng,population) VALUE("Riverside","Riverside","Riverside County","06065","CA","California",33.7437,-115.9938,2437864);

SELECT * FROM counties;