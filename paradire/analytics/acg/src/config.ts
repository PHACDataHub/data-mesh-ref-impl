import dotenv from "dotenv";
import path from "path";

dotenv.config({ path: path.resolve(process.cwd(), "../../.env") });

export const {
    BROKER_HOST,
    BROKER_LOCAL_PORT,
    BROKER2_LOCAL_PORT,
    BROKER3_LOCAL_PORT,
    BROKER4_LOCAL_PORT,
    SCHEMA_REGISTRY_HOST,
    SCHEMA_REGISTRY_PORT,
    F_BROKER_HOST,
    F_BROKER_EXTERNAL_PORT,
    F_SCHEMA_REGISTRY_HOST,
    F_SCHEMA_REGISTRY_PORT,
  } = process.env;
