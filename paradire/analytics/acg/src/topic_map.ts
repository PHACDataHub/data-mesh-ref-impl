import { Kafka } from "kafkajs";
import { SchemaRegistry } from "@kafkajs/confluent-schema-registry";

import { subscribeToTopic } from "./topic_subscriber.js";

export const get_topic_map = (
  kafka: { pt: Kafka; federal: Kafka },
  registry: { pt: SchemaRegistry; federal: SchemaRegistry },
  query_types: string[],
  pt: string
) => {
  return Promise.all(
    [
      {
        name: "CityOrgPatient",
        topic: {
          request: "fed_request_city_org_patient",
          response: "fed_response_city_org_patient",
        },
      },
      {
        name: "CityOrgPatientVisit",
        topic: {
          request: "fed_request_city_org_patient_visit",
          response: "fed_response_city_org_patient_visit",
        },
      },
      {
        name: "CityYearTopProcedure",
        topic: {
          request: "fed_request_city_year_top_proc",
          response: "fed_response_city_year_top_proc",
        },
      },
      {
        name: "PatientCvxOrg",
        topic: {
          request: "fed_request_patient_cvx_org",
          response: "fed_response_patient_cvx_org",
        },
      },
      {
        name: "PtOrgMed",
        topic: {
          request: "fed_request_pt_org_med",
          response: "fed_response_pt_org_med",
        },
      },
      {
        name: "TopKImmunization",
        topic: {
          request: "fed_request_top_k_immunization",
          response: "fed_response_top_k_immunization",
        },
      },
      {
        name: "VaccinationRecord",
        topic: {
          request: "fed_request_vaccination_record",
          response: "fed_response_vaccination_record",
        },
      },
      {
        name: "ZipImmunization",
        topic: {
          request: "fed_request_zip_immunization",
          response: "fed_response_zip_immunization",
        },
      },
    ]
      .filter(({ name }) => query_types.includes(name))
      .map(
        async (sub) =>
          await subscribeToTopic({
            name: sub.name,
            topic: sub.topic,
            kafka,
            registry,
            pt,
          })
      )
  );
};
