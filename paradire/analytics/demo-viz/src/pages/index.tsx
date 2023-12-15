import Head from "next/head";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";

import {
  DatePicker,
  Radio,
  Button,
  Spin,
  Select,
  type RadioChangeEvent,
  Badge,
} from "antd";

import { ReloadOutlined } from "@ant-design/icons";
import dayjs, { type Dayjs } from "dayjs";

import { type AlignedData } from "uplot";

import { api } from "~/utils/api";
import { type SummaryData } from "~/server/api/routers/post";

import Plot from "~/components/Plot";
import {
  maximum_date,
  minimum_date,
  PTs,
  generateEmptyData,
} from "~/utils/common";

const { RangePicker } = DatePicker;

export default function Home() {
  // Which data points to display (yearly, monthly or daily).  Defaults to monthly.
  const [mode, setMode] = useState<"yearly" | "monthly" | "daily">("monthly");

  // Determine the default start date and end date of the visualization.
  const [startDate, setStartDate] = useState<Dayjs>(dayjs("01/01/2014"));
  const [endDate, setEndDate] = useState<Dayjs>(dayjs(maximum_date));

  // Generate a unique client id to allow resuming of data streams if the WS connection is disconnected.
  const [clientId, setClientId] = useState(
    `viz-${(Math.random() + 1).toString(36).substring(7)}`,
  );
  // Whether to enable streaming of events or not.  (If false, no data will be returned)
  // This is really only used to toggle the subscription - in order to force a reconnection.
  const [streamingEnabled, setStreamingEnabled] = useState(true);

  // If enabled, will begin to stream cached data from `cached.json` in the root of the repo
  const [streamingCached, setStreamingCached] = useState(false);

  // If empty, indicates we are polling for the latest request id - otherwise is the selected request id.
  const [requestId, setRequestId] = useState("");

  const pollingRef = useRef<NodeJS.Timeout | null>(null);

  // This is where the data points are stored
  const [summaryData, setSummaryData] =
    useState<SummaryData>(generateEmptyData());

  // Memoized calculation of the sum of all yearly data points.
  // (Only considers year because all sums are the same, and there are less loops here)
  const records = useMemo(
    () =>
      summaryData.year_data
        .filter((_, i) => i > 0)
        .reduce((p, c) => p + c.reduce((c1, c2) => c1 + c2, 0), 0),
    [summaryData],
  );

  // Memoized data sent to the plot - will update automatically if the data or mode change.
  const data = useMemo(() => {
    if (summaryData === null) return [] as AlignedData;
    if (mode === "yearly") return summaryData.year_data as AlignedData;
    if (mode === "monthly") return summaryData.month_data as AlignedData;
    return summaryData.daily_data as AlignedData;
  }, [mode, summaryData]);

  const requestIdQuery = api.post.getRequestIds.useQuery(undefined, {
    refetchOnWindowFocus: false,
  });

  // tRPC subscription hook, when new data arrives update the data via `setSummaryData`.
  api.post.onData.useSubscription(
    { clientId, cached: streamingCached, requestId },
    {
      enabled: streamingEnabled,
      onData(data) {
        setSummaryData(data);
      },
    },
  );

  useEffect(() => {
    if (pollingRef.current) {
      clearTimeout(pollingRef.current);
      pollingRef.current = null;
    }
    if (
      !streamingCached &&
      requestIdQuery.data &&
      requestIdQuery.data.length === 0
    ) {
      const poll = async () => {
        const { data } = await requestIdQuery.refetch();
        if (!data || data.length === 0) {
          pollingRef.current = setTimeout(() => void poll(), 1000);
        } else {
          pollingRef.current = null;
          setRequestId(data[0] ?? "");
        }
      };
      void poll();
    } else if (
      !streamingCached &&
      requestIdQuery.data &&
      requestIdQuery.data.length > 0 &&
      requestId === ""
    ) {
      setRequestId(requestIdQuery.data[0] ?? "");
    }
  }, [streamingCached, requestIdQuery.data, requestId]);

  // Handler called when the mode is changed.
  const modeChangeHandler = useCallback((e: RadioChangeEvent) => {
    const v: string = e.target.value as string;
    if (v === "yearly" || v === "daily" || v === "monthly") setMode(v);
  }, []);

  // Handler called when the date range is changed.
  const dateRangeChangeHandler = useCallback(
    (dates: null | (Dayjs | null)[]) => {
      if (dates) {
        setStartDate(dates[0] ?? dayjs(minimum_date));
        setEndDate(dates[1] ?? dayjs(maximum_date));
      }
    },
    [],
  );

  // Handler called when the reset button is clicked.
  const resetHandler = useCallback(() => {
    // get a new client id to get a new storage bucket on the backend
    setClientId(`viz-${(Math.random() + 1).toString(36).substring(7)}`);

    // zero the data in the browser's memory
    setSummaryData(generateEmptyData());

    // Get the latest request_ids if in streaming mode
    if (!streamingCached) {
      setRequestId("");
      requestIdQuery.remove();
      void requestIdQuery.refetch();
    }

    // toggle streaming on/off
    setStreamingEnabled(false);
    setTimeout(() => setStreamingEnabled(true), 100);
  }, [streamingCached]);

  // Handler called when the stream/simulation selector is changed.
  const cacheHandler = useCallback((e: RadioChangeEvent) => {
    // Perform a reset
    resetHandler();

    // Update cache mode
    setStreamingCached(Boolean(e.target.value));
  }, []);

  const requestChangeHandler = useCallback((value: string) => {
    // Update the request id
    setRequestId(value);

    // zero the data in the browser's memory
    setSummaryData(generateEmptyData());
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
      <main className="flex flex-1 flex-col p-4">
        <div className="flex flex-1">
          <Plot
            data={data}
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
                label: "Since 2014",
                value: [dayjs("01/01/2014"), dayjs()],
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
          <Radio.Group
            options={[
              { label: "Simulate", value: true },
              { label: "Stream", value: false },
            ]}
            value={streamingCached}
            onChange={cacheHandler}
            optionType="button"
            buttonStyle="solid"
          />
          {!streamingCached && (
            <div className="flex flex-1 items-center justify-end space-x-5">
              <Select
                placeholder="Request id"
                value={requestId || undefined}
                onChange={requestChangeHandler}
                options={requestIdQuery.data?.map((ri) => ({
                  value: ri,
                  label: ri,
                }))}
              />
              {((requestId === "" ||
                requestIdQuery.isFetching ||
                requestIdQuery.isLoading) && <Spin />) || (
                <Button
                  shape="circle"
                  icon={<ReloadOutlined />}
                  onClick={resetHandler}
                />
              )}
            </div>
          )}
          {streamingCached && (
            <div className="flex flex-1 justify-end">
              <Button
                onClick={resetHandler}
                className="bg-green-600 text-white"
              >
                Restart
              </Button>
            </div>
          )}
        </div>
      </main>
    </>
  );
}
