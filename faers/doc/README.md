[Back](../README.md)

# Load, analyze, and make FDA Adverse Event Reporting System Data accessible

## A. Purposes
As an example case of the Data Mesh Reference Implementation, it is to show:
1. Demonstrate a setup of a `Kafka Even Sourcing Architecture` as *scalable cluster using only open source components*. The cluster is integrated with `Neo4j` graph database and `NeoDash` for dashboards.
2. Demonstrate ingestion of data in `csv` file format, transformation into *streams of ordered events*, and then seemlesly consumted by `Neo4j`.
3. Demonstrate how datapoints are handled automatically everywhere throughout the process based on *metadata at source*.
4. Demonstrate how *different systems* - such as `Neo4j` or `PowerBI` - *connecting to the streaming infrastructure* in order to consume streams of events, analyze them, and present outcomes in dashboards of choice.
5. Demonstrate how a complex setup of the whole cluster can be *containerized* supporting *setup-on-demand, scale-on-demand, and real-time monitoring*.

&nbsp;

## B. Objectives
As an exercise on the `Healthcare` domain, the example case is to show how to:
1. Perform data ingestion a quarterly dataset from the `FDA Adverse Event Reporting System Data` into a `Kafka - Neo4j cluster` and make them available on `Google Cloud Platform`.
2. Connect `Neo4j` graph database to the cluster, consume data, perform analysis on the dataset. The outcomes then are presented in `NeoDash` cloud dashboards, which are accessible from anywhere.
3. Connect a desktop-based instance of `PowerBI` to the cluster, consume data, perform analysis on the dataset, and then show the outcomes on local dashboards.

<details>
<summary>Credit: The original case</summary>
<p>

**Credit: The original case was described in a [Medium article](https://medium.com/neo4j/healthcare-analytics-sandbox-load-and-analyze-fda-adverse-event-reporting-system-data-with-neo4j-29b7b71a6ef4). Here you can find its [Neo4j blog](https://neo4j.com/developer-blog/healthcare-analytics-sandbox-load-and-analyze-fda-adverse-event-reporting-system-data-with-neo4j/), [GitHub repo](https://github.com/neo4j-graph-examples/healthcare-analytics), and [YouTube video](https://youtu.be/5DZfOLspVDM).**

If you know what is [Neo4j Browser Guide](https://neo4j.com/developer/neo4j-browser/) and how to use it here are the recommended steps:
- Read the article (and the blog if needed);
- Watch the video;
- Then click on this link to create a [Neo4j Sandbox](https://sandbox.neo4j.com/?usecase=healthcare-analytics) in a very short amount of time and go though the guide, as shown below.
![Start screen](../img/neo4j-browser-guide.png)

[Neo4j Life Sciences and Healthcare Network](https://neo4j.com/developer/life-sciences-and-healthcare/) describes use cases in Life Sciences and Healthcare. If you work in biology, biochemistry, pharmaceuticals, healthcare and other life sciences, you know that you work with highly-connected information. Unfortunately, many scientists still use relational databases and spreadsheets as their daily tools.
Here we want to present you with an alternative. Managing, storing and querying connected information is natural to a graph database like `Neo4j`. Learn how your research and practitioner colleagues utilized `Neo4j` to draw new insights or just be more efficient in their daily work.

</p>
</details>

&nbsp;

## C. Health care analytics, FDA FAERS, and the quarterly dataset

### C.1. Health care analytics

Health care analytics is the analysis activities that can be undertaken as a result of data collected from four areas within healthcare: claims and cost data, pharmaceutical and research and development (R&D) data, clinical data (collected from electronic medical records (EHRs)), and patient behavior and sentiment data (patient behaviors and preferences, (retail purchases e.g. data captured in running stores). Health care analytics is a growing industry, expected to grow to even more with time. Health care analytics allows for the examination of patterns in various healthcare data to determine how clinical care can be improved while limiting excessive spending. This can help improve the overall patient care offered in healthcare facilities. -- [Wikipedia](https://en.wikipedia.org/wiki/Health_care_analytics).

Healthcare organizations can *"realize new opportunities and efficiencies by leveraging the connections within their existing data: be it in a connected genome, or a provider network, or patient treatments,"* -- Emil Eifrem, CEO of `Neo4j`.

### C.2 FDA Adverse Event Reporting System (FAERS or AERS)

The FDA Adverse Event Reporting System (FAERS) is a database that contains adverse event reports, medication error reports and product quality complaints resulting in adverse events that were submitted to FDA. The database is designed to support the FDA's post-marketing safety surveillance program for drug and therapeutic biologic products. The informatic structure of the FAERS database adheres to the international safety reporting guidance issued by the International Conference on Harmonisation ([ICH E2B](https://www.fda.gov/drugs/guidances-drugs/international-council-harmonisation-efficacy)). Adverse events and medication errors are coded using terms in the Medical Dictionary for Regulatory Activities ([MedDRA](https://www.meddra.org)) -- [FDA FAERS](https://www.fda.gov/drugs/surveillance/questions-and-answers-fdas-adverse-event-reporting-system-faers).


<details>
<summary>For more details ...</summary>
<p>

FAERS is a useful tool for FDA for activities such as looking for new safety concerns that might be related to a marketed product, evaluating a manufacturer's compliance to reporting regulations and responding to outside requests for information. The reports in FAERS are evaluated by clinical reviewers, in the Center for Drug Evaluation and Research (CDER) and the Center for Biologics Evaluation and Research (CBER), to monitor the safety of products after they are approved by FDA.

If a potential safety concern is identified in FAERS, further evaluation is performed. Further evaluation might include conducting studies using other large databases, such as those available in the [Sentinel System](https://www.fda.gov/sentinel-initiative-transforming-how-we-monitor-product-safety). Based on an evaluation of the potential safety concern, FDA may take regulatory action(s) to improve product safety and protect the public health, such as updating a product’s labeling information, restricting the use of the drug, communicating new safety information to the public, or, in rare cases, removing a product from the market.   

Healthcare professionals, consumers, and manufacturers submit reports to FAERS. FDA receives voluntary reports directly from healthcare professionals (such as physicians, pharmacists, nurses and others) and consumers (such as patients, family members, lawyers and others). Healthcare professionals and consumers may also report to the products’ manufacturers. If a manufacturer receives a report from a healthcare professional or consumer, it is required to send the report to FDA as specified by regulations.

</p>
</details>

### C.3. The quarterly dataset

The `2022 Q4` dataset from the [FDA FAERS Latest Quarterly Data Files](https://www.fda.gov/drugs/questions-and-answers-fdas-adverse-event-reporting-system-faers/fda-adverse-event-reporting-system-faers-latest-quarterly-data-files) is downloaded. Data ingestion is then performed to prepare the FAERS graph and run a few example analytics queries to see interesting output.

&nbsp;

## D. The Kafka + Neo4j Cluster

### D.1. Components

The cluster is constructed from `open source only` components. Three instances of each of `Kafka Broker` and `Kafka Connect` are added to ensure high-performance streaming event handling as well as high throughput for getting data into and out-of `Kafka`.

The cluster ([`docker-compose.yml`](../docker-compose.yml)) consists of:
+ an instance of `Kafka` community edition, constructed as below:
    - `zookeper` ([`Apache Zookeeper`](https://zookeeper.apache.org))
    - three brokers: `broker`, `broker2`, and `broker3` ([`Apache Kafka`](https://kafka.apache.org/documentation.html))
    - `schema-registry` ([`Confluent Schema Registry`](https://github.com/confluentinc/schema-registry))
    - three connects: `connect`, `connect2`, and `connect3` ([`Apache Kafka Connect`](https://kafka.apache.org/documentation.html#connect))
    - `ksqldb-server` ([`Confluent ksqlDB`](https://ksqldb.io/))
    - `ksqldb-cli` ([`Confluent ksqlDB CLI`](https://docs.ksqldb.io/en/latest/operate-and-deploy/installation/cli-config/))
    - `rest-proxy` ([`Confluent Rest Proxy`](https://github.com/confluentinc/kafka-rest))
    - `kafkacat` ([`Kafkacat CLI`](https://docs.confluent.io/platform/current/app-development/kafkacat-usage.html))
    - `kafka-ui` ([`Kafka UI`](https://github.com/provectus/kafka-ui))
+ an instance of `neo4j` ([`Neo4j Graph Database`](https://neo4j.com/product/neo4j-graph-database/)), which is a graph database management system developed by Neo4j, Inc. Described by its developers as an ACID-compliant transactional database with native graph storage and processing.
+ an instance of `neodash` ([`Dashboard Builder for Neo4j`](https://neo4j.com/labs/neodash/)), which supports presenting your data as tables, graphs, bar charts, line charts, maps and more. It contains a Cypher editor to directly write the Cypher queries that populate the reports. You can save dashboards to your database, and share them with others.

![Kafka + Neo4j Cluster](../img/docker-compose.png)

### D.2 Setup and run

<details>
<summary>Setup and start the cluster ...</summary>
<p>

**Important:** the minimal system requirements for the cluster is a (virtual) machine with at least `4 CPUs, 32 GB RAM, 100 GB storage`.

1. Clone the GitHub repository:
```bash
git clone https://github.com/PHACDataHub/data-mesh-ref-impl.git
```

**Important:** 
- the [`.env`](../.env) environment has to be setup with correct IPs for the virtual machine `VM_IP` (local IP if physical machine) and its public interface `PUBLIC_IP`.
- port forwarding need to be configured if remote access is desired for monitoring `Kafka` (8008), `Neo4j` (7473/7474), `NeoDash` (5005), for dashboard designer with `NeoDash` (5006).

2. Install `Docker` and `Docker Compose`:

```bash
./scripts/docker/setup.sh
```

3. Prepare folders for data, logs, and data files:

```bash
./scripts/setup.sh
```

Note that the setup script already downloads the [`2022 Q4`](https://fis.fda.gov/content/Exports/faers_ascii_2022Q4.zip) datasets reside at [`FDA Adverse Event Reporting System (FAERS) Quarterly Data Extract Files`](https://fis.fda.gov/extensions/FPD-QDE-FAERS/FPD-QDE-FAERS.html). To download another quarterly dataset, for example `2022 Q3`, use

```bash
./scripts/download_faers_qdef.sh 2022 Q3
```

The setup script also downloads the [`Geopolitical Entities, Names, and Codes (GENC)`](https://www.fda.gov/industry/structured-product-labeling-resources/geopolitical-entities-names-and-codes-genc). To run the download separately, use

```bash
./scripts/download_genc_terms.sh
```

4. Start the cluster

```bash
./scripts/start_first_time.sh
```

5. Setup `Neo4j` database, create `Spooldir` source connectors, `Neo4` sink connectors, and perform post processing on imported data:

```bash
./scripts/run.sh
```

</p>
</details>


### D.3. (Optional) Other utilities

<details>
<summary>For more details ...</summary>
<p>

1. Stop the cluster

```bash
./scripts/stop.sh
```

2. Restart the cluster (once it has already been set up)

```bash
./scripts/start_again.sh
```

3. Remove the cluster

```bash
./scripts/cleanup.sh
```

</p>
</details>

&nbsp;

## E. The FAERS dataset

### E.1. The 2020 Q4 (October - December 2022) quarterly dataset

The quarterly data files, which are available in `ASCII` or `SGML` formats, include:
- DEMOyyQq.TXT contains patient demographic and administrative information, a single record for each event report. 
- DRUGyyQq.TXT contains drug/biologic information for as many medications as were reported for the event (1 or more per event). 
- REACyyQq.TXT contains all "Medical Dictionary for Regulatory Activities" ([MedDRA](http://www.meddra.org)) terms coded for the adverse event (1 or more).
- OUTCyyQq.TXT contains patient outcomes for the event (0 or more). 
- RPSRyyQq.TXT contains report sources for the event (0 or more). 
- THERyyQq.TXT contains drug therapy start dates and end dates for the reported drugs (0 or more per drug per event). 
- INDIyyQq.TXT contains all "Medical Dictionary for Regulatory Activities" (MedDRA) terms coded for the indications for use (diagnoses) for the reported  drugs (0 or more per drug per event). 

<img src="../img/ASCII-entity-relationship-diagram.png" alt="ASCII Entity Relationship Diagram." width="80%"/>

<details>
<summary>For more details ...</summary>
<p>

For details on columns in each of the files, see [ASC_NTS.pdf](./ASC_NTS.pdf).

**DEMO22Q4.TXT** - patient demographic and administrative information, a single record for each event report (header and first 9 lines)

| primaryid  | caseid   | caseversion | i_f_code | event_dt | mfr_dt   | init_fda_dt | fda_dt   | rept_cod         | auth_num               | mfr_num                                                                                                                                                                                                                                              | mfr_sndr | lit_ref  | age | age_cod | age_grp  | sex | e_sub    | wt       | wt_cod | rept_dt | to_mfr | occp_cod | reporter_country | occr_country |
|------------|----------|-------------|----------|----------|----------|-------------|----------|------------------|------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|----------|-----|---------|----------|-----|----------|----------|--------|---------|--------|----------|------------------|--------------|
| 100115733  | 10011573 | 3           | F        | 20130801 | 20221118 | 20140314    | 20221123 | EXP              | CA-MERCK-1403CAN005674 | MERCK                                                                                                                                                                                                                                                | 75       | YR       | M   | Y       | 58.05    | KG  | 20221123 | HP       | CA     | CA      |        |          |                  |              |
| 1002130537 | 10021305 | 37          | F        | 20210415 | 20220928 | 20140319    | 20221005 | EXP              | PHHY2014CA019281       | NOVARTIS                                                                                                                                                                                                                                             | 43       | YR       | M   | Y       | 20221005 | HP  | CA       | CA       |        |         |        |          |                  |              |
| 100234223  | 10023422 | 3           | F        | 20120301 | 20221003 | 20140320    | 20221007 | EXP              | US-ROCHE-1362929       | ROCHE                                                                                                                                                                                                                                                | 67       | YR       | F   | Y       | 20221007 | LW  | US       |          |        |         |        |          |                  |              |
| 100260594  | 10026059 | 4           | F        | 20120101 | 20221124 | 20140320    | 20221130 | EXP              | DE-BFARM-13321363      | DE-MYLANLABS-2014S1005326                                                                                                                                                                                                                            | MYLAN    | 63       | YR  | M       | Y        | 88  | KG       | 20221130 | HP     | DE      | DE     |          |                  |              |
| 100518358  | 10051835 | 8           | F        | 20130715 | 20221125 | 20140402    | 20221201 | EXP              | CA-ROCHE-1247938       | ROCHE                                                                                                                                                                                                                                                | 50       | YR       | F   | Y       | 59       | KG  | 20221201 | HP       | CA     |         |        |          |                  |              |
| 100614443  | 10061444 | 3           | F        | 20221123 | 20140407 | 20221130    | EXP      | EG-ROCHE-1372609 | ROCHE                  | El-Dosouky I, ElHawari S, Emara M. and Hamed E. Types and predictors of interferon/ribavirin induced cardiac complications in the egyptian patients with chronic hepatitis c virus-Abs. no.P1107. Journal of Hepatology 2014 Apr;60 (SUPP 1):S446-7. | Y        | 20221130 | MD  | EG      |          |     |          |          |        |         |        |          |                  |              |
| 1006401873 | 10064018 | 73          | F        | 20121201 | 20221222 | 20140408    | 20221226 | EXP              | CA-ROCHE-1173339       | ROCHE                                                                                                                                                                                                                                                | 71       | YR       | F   | Y       | 76       | KG  | 20221226 | HP       | CA     |         |        |          |                  |              |
| 100746869  | 10074686 | 9           | F        | 20090714 | 20221222 | 20140414    | 20221230 | EXP              | CA-ROCHE-1383185       | ROCHE                                                                                                                                                                                                                                                | 52       | YR       | M   | Y       | 20221230 | HP  | CA       | CA       |        |         |        |          |                  |              |
| 100832487  | 10083248 | 7           | F        | 20120201 | 20221108 | 20140417    | 20221116 | EXP              | CA-ROCHE-1385175       | ROCHE                                                                                                                                                                                                                                                | 46       | YR       | M   | Y       | 20221116 | CN  | CA       | CA       |        |         |        |          |                  |              |

&nbsp;

**DRUG22Q4.TXT**  - drug/biologic information for as many medications as were reported for the event (1 or more per event) (header and first 9 lines)

| primaryid  | caseid   | drug_seq | role_cod | drugname                 | prod_ai                  | val_vbm | route         | dose_vbm                   | cum_dose_chr | cum_dose_unit | dechal | rechal | lot_num | exp_dt             | nda_num | dose_amt | dose_unit | dose_form | dose_freq |
|------------|----------|----------|----------|--------------------------|--------------------------|---------|---------------|----------------------------|--------------|---------------|--------|--------|---------|--------------------|---------|----------|-----------|-----------|-----------|
| 100115733  | 10011573 | 1        | PS       | JANUVIA                  | SITAGLIPTIN PHOSPHATE    | 1       | Oral          | 100 mg 1 every 1 day       | 6300         | MG            | 21995  | 100    | MG      | Film-coated tablet | QD      |          |           |           |           |
| 100115733  | 10011573 | 2        | C        | ATIVAN                   | LORAZEPAM                | 1       | Unknown       | UNK                        | U            |               |        |        |         |                    |         |          |           |           |           |
| 100115733  | 10011573 | 3        | C        | LOPERAMIDE HYDROCHLORIDE | LOPERAMIDE HYDROCHLORIDE | 1       | Unknown       | UNK                        | U            |               |        |        |         |                    |         |          |           |           |           |
| 100115733  | 10011573 | 4        | C        | METFORMIN                | METFORMIN HYDROCHLORIDE  | 1       | Oral          | UNK                        | U            | Tablet        |        |        |         |                    |         |          |           |           |           |
| 1002130537 | 10021305 | 1        | PS       | SANDOSTATIN              | OCTREOTIDE ACETATE       | 1       | Subcutaneous  | 50 ug (test dose)          | D            | 19667         | 50     | UG     |         |                    |         |          |           |           |           |
| 1002130537 | 10021305 | 2        | SS       | SANDOSTATIN              | OCTREOTIDE ACETATE       | 1       | D             | 19667                      |              |               |        |        |         |                    |         |          |           |           |           |
| 1002130537 | 10021305 | 3        | SS       | SANDOSTATIN              | OCTREOTIDE ACETATE       | 1       | D             | 19667                      |              |               |        |        |         |                    |         |          |           |           |           |
| 1002130537 | 10021305 | 4        | SS       | SANDOSTATIN LAR DEPOT    | OCTREOTIDE ACETATE       | 1       | Intramuscular | 30 mg, QMO (every 4 weeks) | 19667        | 30            | MG     | /MONTH |         |                    |         |          |           |           |           |
| 1002130537 | 10021305 | 5        | SS       | SANDOSTATIN LAR DEPOT    | OCTREOTIDE ACETATE       | 1       | Intramuscular | 30 mg, QMO (every 4 weeks) | 19667        | 30            | MG     | /MONTH |         |                    |         |          |           |           |           |

&nbsp;

**REAC22Q4.TXT**  - all "Medical Dictionary for Regulatory Activities" ([MedDRA](http://www.meddra.org)) terms coded for the adverse event (1 or more) (header and first 9 lines)

| primaryid  | caseid   | pt                               | drug_rec_act |
|------------|----------|----------------------------------|--------------|
| 100115733  | 10011573 | Pancreatitis chronic             |              |
| 100115733  | 10011573 | Pancreatic carcinoma             |              |
| 1002130537 | 10021305 | Injection site haemorrhage       |              |
| 1002130537 | 10021305 | Post procedural complication     |              |
| 1002130537 | 10021305 | Hypopituitarism                  |              |
| 1002130537 | 10021305 | Infection                        |              |
| 1002130537 | 10021305 | Heart rate increased             |              |
| 1002130537 | 10021305 | White blood cell count increased |              |
| 1002130537 | 10021305 | Dyspnoea                         |              |

&nbsp;

**OUTC22Q4.TXT**  - patient outcomes for the event (0 or more) (header and first 9 lines)

| primaryid  | caseid   | outc_cod |
|------------|----------|----------|
| 100115733  | 10011573 | LT       |
| 100115733  | 10011573 | OT       |
| 1002130537 | 10021305 | OT       |
| 1002130537 | 10021305 | HO       |
| 100234223  | 10023422 | HO       |
| 100234223  | 10023422 | OT       |
| 100260594  | 10026059 | OT       |
| 100518358  | 10051835 | OT       |
| 100614443  | 10061444 | OT       |

&nbsp;

**RPSR22Q4.TXT**  - report sources for the event (0 or more) (header and first 9 lines)

| primaryid | caseid   | rpsr_cod |
|-----------|----------|----------|
| 214020341 | 21402034 | HP       |
| 214020451 | 21402045 | CSM      |
| 214021021 | 21402102 | CSM      |
| 214021051 | 21402105 | CSM      |
| 214021571 | 21402157 | CSM      |
| 214022161 | 21402216 | CSM      |
| 214025461 | 21402546 | HP       |
| 214032641 | 21403264 | CSM      |
| 214033011 | 21403301 | FGN      |

&nbsp;

**THER22Q4.TXT**  - contains drug therapy start dates and end dates for the reported drugs (0 or more per drug per event) (header and first 9 lines)

| primaryid  | caseid   | dsg_drug_seq | start_dt | end_dt   | dur | dur_cod |
|------------|----------|--------------|----------|----------|-----|---------|
| 100115733  | 10011573 | 1            | 20120407 | 20120409 | 63  | DAY     |
| 1002130537 | 10021305 | 1            | 20131219 | 20131219 | 1   | DAY     |
| 1002130537 | 10021305 | 4            | 20140114 |          |     |         |
| 1002130537 | 10021305 | 5            | 20191119 |          |     |         |
| 100234223  | 10023422 | 1            | 200905   | 2012     | 3   | YR      |
| 100234223  | 10023422 | 2            | 20100712 | 20111031 | 477 | DAY     |
| 100234223  | 10023422 | 3            | 199908   | 2004     | 5   | YR      |
| 100234223  | 10023422 | 4            | 20000217 | 20040222 | 4   | YR      |
| 100234223  | 10023422 | 5            | 2004     | 2009     | 5   | YR      |

&nbsp;

**INDI22Q4.TXT**  - all "Medical Dictionary for Regulatory Activities" (MedDRA) terms coded for the indications for use (diagnoses) for the reported  drugs (0 or more per drug per event) (header and first 9 lines)

| primaryid  | caseid   | indi_drug_seq | indi_pt                             |
|------------|----------|---------------|-------------------------------------|
| 100115733  | 10011573 | 4             | Type 2 diabetes mellitus            |
| 1002130537 | 10021305 | 1             | Neuroendocrine tumour               |
| 1002130537 | 10021305 | 4             | Neuroendocrine tumour               |
| 1002130537 | 10021305 | 7             | Product used for unknown indication |
| 100234223  | 10023422 | 1             | Osteoporosis                        |
| 100234223  | 10023422 | 3             | Osteoporosis                        |
| 100234223  | 10023422 | 5             | Osteoporosis                        |
| 100234223  | 10023422 | 7             | Fibromyalgia                        |
| 100234223  | 10023422 | 8             | Rheumatoid arthritis                |

</p>
</details>

&nbsp;

### E.2. Getting data from csv files into Kafka and from Kafka into Neo4j

`Kafka UI` is used to monitor the `Kafka` cluster.

<img src="../img/cluster-kafka-ui.png" alt="Kafka UI" width="80%"/>

<details>
<summary>For more details about connectors ...</summary>
<p>

Several connectors are created to import messages for topics.

<img src="../img/kafka-connectors.png" alt="Kafka connectors" width="80%"/>

</p>
</details>

&nbsp;

For each topic, a message represents a row in the corresponding `csv` file.

```bash
`wc -l `find data/faers/2022Q4/ASCII -name '*.txt'`
```
```
   726768 data/faers/2022Q4/ASCII/THER22Q4.txt
  1617585 data/faers/2022Q4/ASCII/REAC22Q4.txt
  1321490 data/faers/2022Q4/ASCII/INDI22Q4.txt
    14399 data/faers/2022Q4/ASCII/RPSR22Q4.txt
   483644 data/faers/2022Q4/ASCII/DEMO22Q4.txt
   334612 data/faers/2022Q4/ASCII/OUTC22Q4.txt
  2006968 data/faers/2022Q4/ASCII/DRUG22Q4.txt
  6505466 total
```

<img src="../img/kafka-topics.png" alt="Kafka topics" width="80%"/>

Here's the topic `faers-demo` for the cases with some messages are shown.

<img src="../img/topic-demo.png" alt="faers-demo topic" width="80%"/>

Detailed of a message inside the topic:

<img src="../img/demo-messages.png" alt="faers-demo message" width="80%"/>

<details>
<summary>For more details about metadata and the schema registry...</summary>
<p>

Messages are handled automatically by the `schema registry`:

<img src="../img/schema-registry.png" alt="Schema Registry" width="80%"/>

The schema for the message's key:

<img src="../img/schema-demo-key.png" alt="faers-demo schema for key" width="80%"/>

The schema for the message's value:

<img src="../img/schema-demo-value.png" alt="faers-demo schema for value" width="80%"/>

</p>
</details>

&nbsp;

### E.3. Neo4j Entities

The `Neo4j` entities are described below. These are the entities that `Neo4j` uses when performing analysis.

| Entity        | Label        | Description                                                                                                                                                                                                                                    |
|---------------|--------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Demographic   | Case         | This is the demographic information of a person involved in the adverse event report.                                                                                                                                                          |
| Drug          | Drug         | Drug involved in the adverse event. A drug can be a primary suspect, secondary suspect, concomitant or interacting drug responsible for the adverse effect. This suspect type is identified by the relationship between Case and Drug Nodes.   |
| Reaction      | Reaction     | This is the reaction that the person (Case) developed after consumption of the respective drug, like 'Pain', 'Body temperature increased' or 'Insomnia' or 'Memory Loss' etc.                                                                  |
| Outcome       | Outcome      | This is the long term outcome of the case after the adverse event, for example 'Hospitalization: Initial or Prolonged', 'Disability' or 'Death'                                                                                                |
| Report_Source | ReportSource | This is the reported of the adverse event, for example 'Health Professional', 'Consumer', 'User Health Facility' etc who has reported the event to FDA system.                                                                                 |
| Therapy       | Therapy      | For some cases, they receive drug as a part of a therapy. This is the therapy details for the case.                                                                                                                                            |
| Indication    | -            | This is the medical term for drug indication that has the details like drug sequence, indication point. We have not used a separate Node label for this, instead we have covered required details as `Case` to `Drug` relationship properties. |
| Demographics  | AgeGroup     | Demographics table in the FEARS data has age information that we turned into a separate node for Age Group reporting.                                                                                                                          |

<img src="../img/model.svg" alt="The Data Model" width="80%"/>
&nbsp;

For example, the case with `primaryid` `58965853` is shown below as a graph of connected entities:

<img src="../img/case-58965853.png" alt="Case 58965853" width="80%"/>

```Cypher
MATCH (c:Case {primaryid: 58965853})
MATCH (c)-[consumed]->(drug:Drug)
MATCH (c)-[:RESULTED_IN]->(outcome)
MATCH (c)-[:HAS_REACTION]->(reaction)
MATCH (therapy)-[prescribed:PRESCRIBED]-(drug)
RETURN c AS patient, collect(distinct reaction) as sideEffects,
collect(distinct(drug)) AS drugs,
collect(distinct(outcome)) as outcomes
```

Thus, the ASCII Entities and Relationships from the FAERS ASCII dataset have to be transformed into `Neo4j` entities and relationships.

<details>
<summary>For more details ...</summary>
<p>

1. Load cases, manufacturers and relate them 

```Cypher
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
```

2. Load other information related to the events 

2.1. Load outcomes and link them with cases 

```Cypher
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
```

2.2. Load reactions and link them with cases 

```Cypher
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
```

2.3. Load report sources and link them with cases 

```Cypher
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
```

3. Load drugs and therapies

3.1. Load drugs with indications and link them with cases using relationships based on their roles for the cases

```Cypher
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
```

3.2. Load therapies and link them with cases and drugs 

```Cypher
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
```

</p>
</details>

&nbsp;

## F. Performing Data Analytics with Neo4j and Dashboarding with Neodash

Navigate your browser to `http://<PUBLIC_IP>:5005`. 

You need to login for the first time ...</summary>

<img src="../img/neodash-login.png" alt="Neodash Login" width="80%"/>

<details>
<summary>If you need to setup NeoDash dashboard ...</summary>
<p>

Navigate your browser to `http://<PUBLIC_IP>:5006`. Your instance of [Neodash](https://neo4j.com/labs/neodash/) should already be running there.

<img src="../img/neodash-new-dashboard.png" alt="Neodash New Dashboard" width="80%"/>

Choose to create a new dashboard, then use with `neo4j` and `phac2023` as credential.

And finally click the `Load Dashboard` button on the left menu panel, then paste in the content of [neodash_dashboard.json](../conf/neo4j/dashboard.json), which was created by the `Cypher` queries below.

<img src="../img/neodash-load-dashboard.png" alt="Neodash Load Dashboard" width="80%"/>

</p>
</details>

&nbsp;


### F.1. Side Effects

1. What are the top 5 side effects reported?

```Cypher
MATCH (c:Case)-[:HAS_REACTION]->(r:Reaction) 
RETURN r.description AS description, count(c) As count
ORDER BY count(c) DESC 
LIMIT 5;
```

2. What are the top 5 drugs reported with side effects? Get drugs along with their side effects?

```Cypher
MATCH (c:Case)-[:IS_PRIMARY_SUSPECT]->(d:Drug)
MATCH (c)-[:HAS_REACTION]->(r:Reaction)
WITH d.name as drugName, collect(r.description) as sideEffects, count(r.description) as totalSideEffects
RETURN drugName, sideEffects[0..5] as sideEffects, totalSideEffects 
ORDER BY totalSideEffects DESC LIMIT 5;
```

<img src="../img/side-effects.png" alt="Side Effects" width="80%"/>

### F.2. Companies

1. What are the manufacturing companies which have most drugs which reported side effects?

```Cypher
MATCH (m:Manufacturer)-[:REGISTERED]->(c)-[:HAS_REACTION]->(r)
RETURN m.manufacturerName as company, count(distinct r) as numberOfSideEffects
ORDER BY numberOfSideEffects DESC LIMIT 5;
```

2. Top 5 registered Drugs and their Side Effects
* What are the top 5 drugs from a particular company with side effects? 
* What are the side effects from those drugs?

```Cypher
MATCH (m:Manufacturer {manufacturerName: 'NOVARTIS'})-[:REGISTERED]->(c)
MATCH (r:Reaction)<--(c)-[:IS_PRIMARY_SUSPECT]->(d)
WITH d.name as drug,collect(distinct r.description) AS reactions, count(distinct r) as totalReactions
RETURN drug, reactions[0..5] as sideEffects, totalReactions 
ORDER BY totalReactions DESC
LIMIT 5;
```
*It is important to note that in the `Parameter Select` box of the `Manufacturer` you can chose the company by typing part of its name, for example `TAK` for `TAKEDA`.*

<img src="../img/companies.png" alt="Companies" width="80%"/>

### F.3. Consumer Reports

1. What are the top 5 drugs which are reported directly by consumers for the side effects?

```Cypher
MATCH (c:Case)-[:REPORTED_BY]->(rpsr:ReportSource {name: "Consumer"})
MATCH (c)-[:IS_PRIMARY_SUSPECT]->(d)
MATCH (c)-[:HAS_REACTION]->(r)
WITH rpsr.name as reporter, d.name as drug, collect(distinct r.description) as sideEffects, count(distinct r) as total
RETURN drug, reporter, sideEffects[0..5] as sideEffects 
ORDER BY total desc LIMIT 5;
```

2. What are the top 5 drugs whose side effects resulted in Death of patients as an outcome?

```Cypher
MATCH (c:Case)-[:RESULTED_IN]->(o:Outcome {outcome:"Death"})
MATCH (c)-[:IS_PRIMARY_SUSPECT]->(d)
MATCH (c)-[:HAS_REACTION]->(r)
WITH d.name as drug, collect(distinct r.description) as sideEffects, o.outcome as outcome, count(distinct c) as cases
RETURN drug, sideEffects[0..5] as sideEffects, outcome, cases
ORDER BY cases DESC
LIMIT 5;
```

<img src="../img/consumer-reports.png" alt="Consumer Reports" width="80%"/>

### F.4. Drug Combination and Case Details

1. Show top 10 drug combinations which have most side effects when consumed together

```Cypher
MATCH (c:Case)-[:IS_PRIMARY_SUSPECT]->(d1)
MATCH (c:Case)-[:IS_SECONDARY_SUSPECT]->(d2)
MATCH (c)-[:HAS_REACTION]->(r)
MATCH (c)-[:RESULTED_IN]->(o)
WHERE d1<>d2
WITH d1.name as primaryDrug, d2.name as secondaryDrug,
collect(r.description) as sideEffects, count(r.description) as totalSideEffects, collect(o.outcome) as outcomes
RETURN primaryDrug, secondaryDrug, sideEffects[0..3] as sideEffects, totalSideEffects, outcomes[0] ORDER BY totalSideEffects desc
LIMIT 10;
```

2. Take one of the case, and list demographics, all the drugs given, side effects and outcome for the patient.
This actually is split into three panels.

```Cypher
MATCH (c:Case {primaryid: 111791005})
MATCH (c)-[consumed]->(drug:Drug)
MATCH (c)-[:RESULTED_IN]->(outcome)
MATCH (c)-[:HAS_REACTION]->(reaction)
MATCH (therapy)-[prescribed:PRESCRIBED]-(drug)
WITH distinct c.age + ' ' + c.ageUnit as age, c.gender as gender,
collect(distinct reaction.description) as sideEffects,
collect(
    distinct {   drug: drug.name,
        dose: consumed.doseAmount + ' '  + consumed.doseUnit,
        indication: consumed.indication,
        route: consumed.route
    }) as treatment,
collect(distinct outcome.outcome) as outcomes
RETURN age, gender, treatment, sideEffects, outcomes ;
```

*It is important to note that in the `Parameter Select` box of the `Manufacturer` you can chose the case by typing part of its identification.*

<img src="../img/drug-combination-and-case-details.png" alt="Drug Combination and Case Details" width="80%"/>

### F.5. Age Groups

1. What is the age group which reported highest side effects, and what are those side effects?

```Cypher
MATCH (a:AgeGroup)<-[:FALLS_UNDER]-(c:Case)
MATCH (c)-[:HAS_REACTION]->(r)
WITH a, collect(r.description) AS sideEffects, count(r) AS total
RETURN a.ageGroup AS ageGroupName, sideEffects[0..6] AS sideEffects 
ORDER BY total DESC
LIMIT 1;
```

2. What are the highest side effects reported in Children and what are the drugs those caused these side effects?

```Cypher
MATCH (a:AgeGroup {ageGroup:"C"})<-[:FALLS_UNDER]-(c)
MATCH (c)-[:HAS_REACTION]->(r)
MATCH (c)-[:IS_PRIMARY_SUSPECT]->(d)
WITH distinct r.description as sideEffect, collect(distinct d.name) as drugs, count(r) as sideEffectCount
RETURN sideEffect, drugs 
ORDER BY sideEffectCount desc LIMIT 5;
```

3. What is the percentage wise allocation of side effects for each age group?

```Cypher
MATCH (c:Case)-[:HAS_REACTION]->(r)
WITH count(r) as totalReactions
MATCH (a:AgeGroup)<-[:FALLS_UNDER]-(c)-[:HAS_REACTION]->(r)
WITH a, count(r) as ageGroupWiseReactions, totalReactions
RETURN a.ageGroup as ageGroupName, (ageGroupWiseReactions*100.00)/totalReactions as perc
ORDER BY perc DESC
```

<img src="../img/age-groups.png" alt="Age Groups" width="80%"/>


To save the dashboard for later use, select the `Save` button on the left menu and then save it into `Neo4j` instance (the dashboard now is a part of the `Neo4j` database.)

## G. [Alternative Visualization with Power BI](#power-bi-viz)

If you have a licensed version of [Power BI Desktop](https://powerbi.microsoft.com/en-us/desktop/) installed on your machine, you can access and visualize `Cypher` queries directly from `Power BI`.

The pre-configured `Power BI` report can be downloaded directly [here](../conf/pbix/fda-adverse-remote.pbix).

<details>
<summary>If you have not configure Power BI to connect to Neo4j before, then follow the instructions here ...</summary>
<p>

First, install the [Neo4j DataConnector For Power BI](https://github.com/cskardon/Neo4jDataConnectorForPowerBi), just follow the instructions below:
- Copy the driver to your `<user>/Documents/Power BI Desktop/Custom Connectors` folder (if you don't have that folder - create it!)
- Allow `Power BI` to see the connector: Open `Power BI`, Go to `File -> Options and Settings -> Options`, Select `Security` from the left hand side bar, in the `Data Extensions` section, select: `(Not Recommended) Allow any extension to load without validation or warning`, say `OK`. Close and restart `Power BI`.
- Click on `Get Data` and choose `Neo4j 2.0 (Beta)`.

</p>
</details>

&nbsp;

Let choose the `Cypher` associated to *What are the top 5 side effects reported?*

```Cypher
MATCH (c:Case)-[:HAS_REACTION]->(r:Reaction) 
RETURN r.description AS description, count(c) As count
ORDER BY count(c) DESC 
LIMIT 5;
```

put it into the `Cypher` text box of the `Execute Cypher Output`, let `http` be the `Scheme`, `localhost` as `Address`, `7474` for `port`, `4.3` as `Neo4j Version` (although we have a higher one, which is backward-compatible), `neo4j` as `Database Name`, and `30` seconds for timeout.

<img src="../img/power-bi-cypher-config.png" alt="[Power BI - Neo4j configuration" width="65%"/>

Then by executing and configuring the dashboard. Happy viz!

<img src="../img/power-bi-top-5-side-effects.png" alt="[Power BI - Top 5 Side effects" width="65%"/>

Similarly with the second report *What are the top 5 drugs reported with side effects? Get drugs along with their side effects?*

<img src="../img/power-bi-top-5-drugs.png" alt="[Power BI - Top 5 Drugs with side effects" width="65%"/>

[Back](../../README.md)