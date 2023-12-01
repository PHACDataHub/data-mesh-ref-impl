import Head from "next/head";

import { useCallback, useEffect, useRef, useState } from "react";

import { DatePicker, Radio, type RadioChangeEvent, Badge } from "antd";
import dayjs, { type Dayjs } from "dayjs";

import { type AlignedData } from "uplot";

import { api } from "~/utils/api";
import { type PT } from "~/server/api/routers/post";
import Plot from "~/components/Plot";

const { RangePicker } = DatePicker;

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
const days: number[] = [];
for (
  let y = minimum_date.getFullYear();
  y <= maximum_date.getFullYear();
  y += 1
) {
  years.push(Date.parse(`01/01/${y}`) / 1000);
  for (let m = 1; m <= 12; m += 1) {
    months.push(Date.parse(`${m}/01/${y}`) / 1000);
  }
}
for (
  let day = new Date(minimum_date);
  day <= maximum_date;
  day.setDate(day.getDate() + 1)
) {
  days.push(day.getTime() / 1000);
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
  const daily_data = useRef<number[][]>([
    days,
    ...PTs.map(() => (Array(days.length) as number[]).fill(0)),
  ]);

  const [records, setRecords] = useState(0);
  const [mode, setMode] = useState<"yearly" | "monthly" | "daily">("yearly");

  const [startDate, setStartDate] = useState<Dayjs>(dayjs("01/01/2005"));
  const [endDate, setEndDate] = useState<Dayjs>(dayjs(maximum_date));

  const getData = useCallback(() => {
    if (mode === "yearly") return year_data.current as AlignedData;
    if (mode === "monthly") return month_data.current as AlignedData;
    return daily_data.current as AlignedData;
  }, [mode]);

  const modeChangeHandler = useCallback((e: RadioChangeEvent) => {
    const v: string = e.target.value as string;
    if (v === "yearly" || v === "daily" || v === "monthly") setMode(v);
  }, []);

  api.post.onData.useSubscription(undefined, {
    enabled: true,
    onData(data) {
      const d = new Date(data.immunization_date);
      const y = d.getFullYear();
      const m = d.getMonth() + 1;
      const day = d.getDate();

      const pt_index = PTs.indexOf(data.pt);
      const y_index = year_data.current[0]?.indexOf(
        Date.parse(`01/01/${y}`) / 1000,
      );
      const m_index = month_data.current[0]?.indexOf(
        Date.parse(`${m}/01/${y}`) / 1000,
      );
      const d_index = daily_data.current[0]?.indexOf(
        Date.parse(`${m}/${day}/${y}`) / 1000,
      );

      const pt_y_row = year_data.current[pt_index + 1];
      const pt_m_row = month_data.current[pt_index + 1];
      const pt_d_row = daily_data.current[pt_index + 1];

      if (
        pt_y_row &&
        pt_m_row &&
        pt_d_row &&
        typeof y_index === "number" &&
        y_index >= 0 &&
        typeof m_index === "number" &&
        m_index >= 0 &&
        typeof d_index === "number" &&
        d_index >= 0
      ) {
        pt_y_row[y_index] += 1;
        pt_m_row[m_index] += 1;
        pt_d_row[d_index] += 1;
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
    }, 100);
    return () => {
      clearInterval(t);
    };
  }, []);

  const dateRangeChangeHandler = useCallback(
    (dates: null | (Dayjs | null)[]) => {
      if (dates) {
        setStartDate(dates[0] ?? dayjs(minimum_date));
        setEndDate(dates[1] ?? dayjs(maximum_date));
      }
    },
    [],
  );

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
      <main className="flex flex-1 flex-col p-4">
        <div className="flex flex-1">
          <Plot
            records={records}
            data={getData()}
            PTs={PTs}
            start={Date.parse(startDate.format("MM/DD/YYYY")) / 1000}
            stop={Date.parse(endDate.format("MM/DD/YYYY")) / 1000}
          />
        </div>
        <div className="flex items-center space-x-10">
          <span className="text-sm">
            <Badge
              style={{ backgroundColor: records === 0 ? "red" : "#52c41a" }}
              count={
                records > 0
                  ? Intl.NumberFormat("en-CA").format(records)
                  : "No data"
              }
            />
          </span>
          <RangePicker
            value={[startDate, endDate]}
            presets={[
              {
                label: "Since 1945",
                value: [dayjs(minimum_date), dayjs()],
              },
              {
                label: "Since 2005",
                value: [dayjs("01/01/2005"), dayjs()],
              },
              {
                label: "2019 - 2022",
                value: [dayjs("01/01/2019"), dayjs("12/31/2022")],
              },
            ]}
            onChange={dateRangeChangeHandler}
          />
          <Radio.Group
            options={[
              { label: "Daily", value: "daily" },
              { label: "Monthly", value: "monthly" },
              { label: "Yearly", value: "yearly" },
            ]}
            value={mode}
            onChange={modeChangeHandler}
            optionType="button"
            buttonStyle="solid"
          />
        </div>
      </main>
    </>
  );
}
