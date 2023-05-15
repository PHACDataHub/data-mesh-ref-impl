[Back](../README.md)

# Imaginative US Vaccination Data Management

## A. Purposes

As an exercise on vaccination data management, it is to:
1. Demonstrate vaccination acvitity at state level, where vaccination records, part of EHR/EMR, collected/updated by HIS and similar systems.
2. Demonstrate interactions with state-level vaccination registry via standard exchange protocols
3. Demonstrate data governance capabilities of state- and federal-level vaccination registries via anonymization, encryption, validation, deduplication, and audit.
4. Demonstrate interactions with state- and federal-level vaccination registries to provide aggregated/filtered/transformed data for analyses by health information analysts, scientists, and policy makers.
5. Demonstrate *down-stream* information flows from federal institutions, health information standards, vaccine regulatory institutes to state-level entities.
6. Demonstrate interactions with state- and federal-level vaccination registries in order to support public domain entities such as international health organizations, regulatory standards, and scientific institutes.
7. Demonstrate support for direct access from citizens to submit, update, and obtain vaccination records for verification pruposes (health providers, schools, border agency).
8. Demonstrate coordination with vaccine manufactures and supply chains.

&nbsp;

## B. Objectives

As an example case of the Data Mesh Reference Implementation,
1. Multiple `Kafka` event sourcing clusters connected and automatically updated by `MirrorMaker`
2. Exchange protocol based on `HL7` with outdated transport layer `SOAP` now replaced by `Apache AVRO` messages as `Kafaka` events.
3. In-stream transformation to aggregate/filter/transform data in order to maintain consistent vaccination data.
4. Data governance based on metadata cataloguing, distinct policies for sensitive information items, anonymization and/or encryption.
5. Data lineage to monitor and collect evidence for later audit.
