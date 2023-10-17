# !/bin/sh

#####
# https://en.wikipedia.org/wiki/Demographics_of_Canada
#####

# Tests
#
# ./run_synthea -p 3 Alberta
# ./run_synthea -p 3 "British Columbia"
# ./run_synthea -p 3 Manitoba
# ./run_synthea -p 3 "New Brunswick"
# ./run_synthea -p 3 "Newfoundland and Labrador"
# ./run_synthea -p 3 "Northwest Territories"
# ./run_synthea -p 3 "Nova Scotia"
# ./run_synthea -p 3 Nunavut
# ./run_synthea -p 3 Ontario
# ./run_synthea -p 3 "Prince Edward Island"
# ./run_synthea -p 3 Quebec
# ./run_synthea -p 3 Saskatchewan
# ./run_synthea -p 3 Yukon

#####
#
# Sampling size 1,171,249 patients
#
# +---------------------------+------------+--------+---------+
# | Alberta                   | 4,262,635  | 11.52% | 130,493 |
# +---------------------------+------------+--------+---------+
# | British Columbia          | 5,000,879  | 13.52% | 159,646 |
# +---------------------------+------------+--------+---------+
# | Manitoba                  | 1,342,153  | 3.63%  | 42,205  |
# +---------------------------+------------+--------+---------+
# | New Brunswick             | 775,610    | 2.09%  | 24,940  |
# +---------------------------+------------+--------+---------+
# | Newfoundland and Labrador | 510,550    | 1.38%  | 16,331  |
# +---------------------------+------------+--------+---------+
# | Northwest Territories     | 41,070     | 0.11%  | 1,211   |
# +---------------------------+------------+--------+---------+
# | Nova Scotia               | 969,383    | 2.62%  | 31,157  |
# +---------------------------+------------+--------+---------+
# | Nunavut                   | 36,858     | 0.10%  | 1,079   |
# +---------------------------+------------+--------+---------+
# | Ontario                   | 14,223,942 | 38.45% | 450,131 |
# +---------------------------+------------+--------+---------+
# | Prince Edward Island      | 154,331    | 0.42%  | 5,001   |
# +---------------------------+------------+--------+---------+
# | Quebec                    | 8,501,833  | 22.98% | 272,051 |
# +---------------------------+------------+--------+---------+
# | Saskatchewan              | 1,132,505  | 3.06%  | 35,787  |
# +---------------------------+------------+--------+---------+
# | Yukon                     | 40,232     | 0.11%  | 1,216   |
# +---------------------------+------------+--------+---------+
#
#####

sampling_size=$1

./run_synthea -p $sampling_size Alberta
./run_synthea -p $sampling_size "British Columbia"
./run_synthea -p $sampling_size Manitoba
./run_synthea -p $sampling_size "New Brunswick"
./run_synthea -p $sampling_size "Newfoundland and Labrador"
./run_synthea -p $sampling_size "Northwest Territories"
./run_synthea -p $sampling_size "Nova Scotia"
./run_synthea -p $sampling_size Nunavut
./run_synthea -p $sampling_size Ontario
./run_synthea -p $sampling_size "Prince Edward Island"
./run_synthea -p $sampling_size Quebec
./run_synthea -p $sampling_size Saskatchewan
./run_synthea -p $sampling_size Yukon