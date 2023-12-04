import { type NextApiRequest, type NextApiResponse } from "next";
import { env } from "~/env.js";

const envVarByName = (req: NextApiRequest, res: NextApiResponse) => {
  const { name } = req.query;
  if (name === "WS_URL") {
    res.status(200).json({ [name]: env[name] ?? "" });
  } else {
    return res.status(403).json({ error: "Unauthorized." });
  }
};

export default envVarByName;
