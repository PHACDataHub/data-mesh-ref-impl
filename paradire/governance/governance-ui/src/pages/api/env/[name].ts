import { type NextApiRequest, type NextApiResponse } from "next";
import { env } from "~/env.mjs";

const envVarByName = (req: NextApiRequest, res: NextApiResponse) => {
  const { name } = req.query;
  if (name === "GOVERNANCE_WS_URL") {
    res.status(200).json({ [name]: env[name] ?? "" });
  } else {
    return res.status(403).json({ error: "Unauthorized." });
  }
};

export default envVarByName;
