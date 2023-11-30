import Head from "next/head";
import { useCallback, useEffect, useReducer, useRef, useState } from "react";

import { api } from "~/utils/api";
import { type PT } from "~/server/api/routers/post";
import Plot from "~/components/Plot";

const PTs: PT[] = [
  "YT",
  "SK",
  "QC",
  "PE",
  "ON",
  "NU",
  "NT",
  "NS",
  "NL",
  "NB",
  "MB",
  "BC",
  "AB",
];

const minimum_date = new Date("01/01/1945");
const maximum_date = new Date(Date.now());

const years: number[] = [];
const months: number[] = [];
for (
  let y = minimum_date.getFullYear();
  y <= maximum_date.getFullYear();
  y += 1
) {
  years.push(Date.parse(`01/01/${y}`) / 1000);
  for (let m = 1; m <= 12; m += 1) {
    months.push(Date.parse(`01/${m}/${y}`) / 1000);
  }
}

export default function Home() {
  const year_data = useRef<number[][]>([
    years,
    ...PTs.map(() => (Array(years.length) as number[]).fill(0)),
  ]);
  const month_data = useRef<number[][]>([
    months,
    ...PTs.map(() => (Array(months.length) as number[]).fill(0)),
  ]);

  const [records, setRecords] = useState(0);

  api.post.onData.useSubscription(undefined, {
    enabled: true,
    onData(data) {
      const d = new Date(data.immunization_date);
      const y = d.getFullYear();
      const m = d.getMonth();

      const pt_index = PTs.indexOf(data.pt);
      const y_index = year_data.current[0]?.indexOf(
        Date.parse(`01/01/${y}`) / 1000,
      );
      const m_index = month_data.current[0]?.indexOf(
        Date.parse(`01/${m}/${y}`) / 1000,
      );

      const pt_y_row = year_data.current[pt_index + 1];
      const pt_m_row = month_data.current[pt_index + 1];

      if (
        pt_y_row &&
        pt_m_row &&
        typeof y_index === "number" &&
        y_index >= 0 &&
        typeof m_index === "number" &&
        m_index >= 0
      ) {
        pt_y_row[y_index] += 1;
        pt_m_row[m_index] += 1;
      }
    },
  });

  useEffect(() => {
    const t = setInterval(() => {
      setRecords(
        year_data.current
          .filter((_, i) => i > 0)
          .reduce((p, c) => p + c.reduce((c1, c2) => c1 + c2, 0), 0),
      );
    }, 1000);
    return () => {
      clearInterval(t);
    };
  }, []);

  return (
    <>
      <Head>
        <title>Paradire Realtime Visualization Demo</title>
        <meta
          name="description"
          content="Examples of realtime visualization for Paradire"
        />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main className="flex h-screen flex-col p-2">
        <div className="flex-1">
          <Plot
            records={records}
            title="Total yearly vaccinations per PT"
            data={year_data.current}
            PTs={PTs}
            start={Date.parse("01/01/2005") / 1000}
          />
        </div>
        <div>
          <span className="text-sm">
            Available records: {Intl.NumberFormat("en-CA").format(records)}.
          </span>
        </div>
      </main>
    </>
  );
}
