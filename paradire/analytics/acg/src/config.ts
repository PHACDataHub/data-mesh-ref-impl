import dotenv from "dotenv";
import path from "path";

dotenv.config({ path: path.resolve(process.cwd(), "../../.env") });

export const {
  BROKER_LIST,
  BROKER_HOST,
  BROKER_INTERNAL_PORT,
  BROKER2_HOST,
  BROKER2_INTERNAL_PORT,
  BROKER3_HOST,
  BROKER3_INTERNAL_PORT,
  BROKER4_HOST,
  BROKER4_INTERNAL_PORT,
  SCHEMA_REGISTRY_URL,
  SCHEMA_REGISTRY_HOST,
  SCHEMA_REGISTRY_PORT,
  F_BROKER_HOST,
  F_BROKER_EXTERNAL_PORT,
  F_BROKER_LIST,
  F_SCHEMA_REGISTRY_HOST,
  F_SCHEMA_REGISTRY_PORT,
  PT,
} = process.env;

if (!PT) throw new Error("PT environment variable is required.");
