/**
 * Code here is imported by both the frontend and backend - so all code
 * in this file must safely run in both environments.
 */
import { type SummaryData, type PT } from "~/server/api/routers/post";

// Define the earliest possible date for our data.
export const minimum_date = new Date(Date.UTC(1945, 0, 1));

// Define the last possible date for our data.
// *** Note over time the server value will drift from the client value - this
// *** is not a problem for this PoC.
export const maximum_date = new Date(Date.now());

// Define the list of PTs that are participating in the query.
export const PTs: PT[] = [
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

// Identify all possible data point possible in yearly, monthly and daily modes
const years: number[] = [];
const months: number[] = [];
const days: number[] = [];
for (
  let y = minimum_date.getFullYear();
  y <= maximum_date.getFullYear();
  y += 1
) {
  years.push(Date.UTC(y, 0, 1) / 1000);
  for (let m = 0; m < 12; m += 1) {
    months.push(Date.UTC(y, m, 1) / 1000);
  }
}
for (
  let day = new Date(minimum_date);
  day <= maximum_date;
  day.setDate(day.getDate() + 1)
) {
  days.push(day.getTime() / 1000);
}

/**
 * Create an array in the uPlot format with all values set to 0 for each
 * data mode.  (yearly, monthly and yearly)
 * @returns SummaryData
 */
export function generateEmptyData(): SummaryData {
  const year_data: number[][] = [
    years,
    ...PTs.map(() => (Array(years.length) as number[]).fill(0)),
  ];
  const month_data: number[][] = [
    months,
    ...PTs.map(() => (Array(months.length) as number[]).fill(0)),
  ];
  const daily_data: number[][] = [
    days,
    ...PTs.map(() => (Array(days.length) as number[]).fill(0)),
  ];
  return { year_data, month_data, daily_data };
}
