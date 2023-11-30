import { useCallback, useEffect, useRef } from "react";
import ColorScheme from "color-scheme";

import uPlot from "uplot";
import "uplot/dist/uPlot.min.css";

import { type PT } from "~/server/api/routers/post";

const scheme = new ColorScheme();
scheme.from_hue(21).scheme("triade").variation("soft");
const colors: string[] = scheme.colors();

const legend_height = 100;

const initialize_uplot = (
  title: string,
  container: HTMLDivElement,
  PTs: PT[],
  width: number,
  height: number,
) => {
  const opts = {
    title,
    width,
    height,
    cursor: {
      drag: {
        setScale: false,
      },
    },
    // tzDate: (ts: number) => uPlot.tzDate(new Date(ts * 1e3), "Etc/UTC"),
    // fmtDate: tpl => uPlot.fmtDate(tpl, ruNames),
    series: [
      {
        label: "X",
      },
    ].concat(
      PTs.map((pt, i) => ({
        // scale: "V",
        label: pt,
        stroke: `#${colors[i]}`,
      })),
    ),
    axes: [{}, { label: "Vaccinations", show: true, grid: { show: true } }],
    // scales: {
    //   V: {
    //     auto: true,
    //     //   range: () => [min ?? 0, max ?? 3000],
    //   },
    // },
  };
  container.innerHTML = "";
  return new uPlot(opts, [], container);
};

export default function Plot({
  PTs,
  title,
  data,
  records,
  start,
  stop,
}: {
  PTs: PT[];
  title: string;
  data: number[][];
  records: number;
  start?: number;
  stop?: number;
}) {
  const graph_container = useRef<HTMLDivElement>(null);
  const ref = useRef<{ plot: uPlot | null }>({ plot: null });

  useEffect(() => {
    const resize = () => {
      if (graph_container.current) {
        const rect = graph_container.current.getBoundingClientRect();
        if (!ref.current.plot) {
          console.log("init!");
          ref.current.plot = initialize_uplot(
            title,
            graph_container.current,
            PTs,
            rect.width,
            rect.height,
          );
        } else {
          ref.current.plot.setSize({
            width: rect.width,
            height: rect.height - legend_height,
          });
        }
      }
    };
    window.addEventListener("resize", resize);
    setTimeout(resize, 100);
    return () => {
      window.removeEventListener("resize", resize);
    };
  }, [PTs, title]);

  const play = useCallback(
    (position: number, window: number, data: number[][], plot: uPlot) => {
      console.log(
        `Playing from position ${position} using a window of ${window}.`,
      );
      if (data.length > 0) {
        if (Array.isArray(data[0]) && data[0].length > position) {
          const start =
            data[0].length > position
              ? new Date(data[0][position]).getFullYear()
              : "N/A";
          const end = data[0][position + window]
            ? new Date(data[0][position + window]).getFullYear()
            : "N/A";
          console.log(`Playing from ${start} to ${end}`);
          plot.setData(data.map((d) => d.slice(position, position + window)));
          // const step = (window / 2).toFixed(0);
          //   const step = 2;
          //   if (data[0]?.length > position + window) {
          //     setTimeout(() => play(position + step, window, data, plot), 100);
          //   }
        }
      }
    },
    [],
  );

  useEffect(() => {
    const setData = (d: number[][]) => {
      if (!ref.current.plot) {
        setTimeout(() => setData(d), 200);
        return;
      }
      if (ref.current.plot && Array.isArray(d[0])) {
        const s = typeof start === "number" ? d[0].indexOf(start) : 0;
        const w =
          typeof stop === "number" ? d[0].indexOf(stop) : d[0].length;
        play(s, w - s, d, ref.current.plot);
      }
    };
    setData(data);
  }, [data, records, start, stop]);

  return <div ref={graph_container} className="h-full" />;
}
