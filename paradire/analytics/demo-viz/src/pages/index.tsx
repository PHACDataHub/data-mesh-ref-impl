import Head from "next/head";
import { useEffect, useReducer, useRef, useState } from "react";

import uPlot from "uplot";
import "uplot/dist/uPlot.min.css";

import ColorScheme from "color-scheme";

// import * as Rickshaw from "rickshaw";

const scheme = new ColorScheme();
scheme.from_hue(21).scheme("triade").variation("soft");

const colors: string[] = scheme.colors();

const PTs = [
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

import { api } from "~/utils/api";

const max_points = 60;

export default function Home() {
  const graph_container = useRef<HTMLDivElement>(null);
  const plot = useRef<uPlot>(null);

  api.post.onData.useSubscription(undefined, {
    enabled: true,
    onData(data) {
      console.log(data);
    }
  })


  useEffect(() => {
    if (graph_container.current && !plot.current) {
      const opts = {
        title: "Vaccination Status",
        width: 800,
        height: 300,
        cursor: {
          drag: {
            setScale: false,
          },
        },
        select: {
          show: false,
        },
        // tzDate: (ts: number) => uPlot.tzDate(new Date(ts * 1e3), "Etc/UTC"),
        // fmtDate: tpl => uPlot.fmtDate(tpl, ruNames),
        series: [
          {
            label: "X",
          },
        ].concat(PTs.map((pt, i) => ({ label: pt, stroke: `#${colors[i]}` }))),
      };
      const yrs: number[] = [1950, 1951, 1952];
      // for (let x = 1950; x += 1; x <= 1960) {yrs.push(x);}
      const mos = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec".split(",");
      const ts: number[] = [];
      yrs.forEach((y) => {
        mos.forEach((m) => {
          ts.push(Date.parse("01 " + m + " " + y + " 00:00:00 UTC") / 1000);
        });
      });

      const data = [ts];
      PTs.forEach((pt) => {
        data.push(ts.map((t, i) => Math.floor(Math.random() * 500)));
      });

      plot.current = new uPlot(opts, data, graph_container.current);
      setInterval(() => {
        const nd = data.map((d, i) => {
          if (i === 0) {
            d.splice(0, 1);
            d.push(d[d.length - 1] + 356 * 60 * 60);
            return d;
          }
          d.splice(0, 1);
          d.push(Math.floor(Math.random() * 500));
          return d;
          // .filter((_, i) => i !== 0)
          // .concat([vals[Math.floor(Math.random() * vals.length)]]);
        });
        console.log(nd[1].length);
        plot.current.setData(nd);
      }, 1000);
    }
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
      <div ref={graph_container} />
    </>
  );
}
