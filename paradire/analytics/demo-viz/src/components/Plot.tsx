import { useCallback, useEffect, useRef } from "react";
import ColorScheme from "color-scheme";

import uPlot, { type AlignedData } from "uplot";
import "uplot/dist/uPlot.min.css";

import { type PT } from "~/server/api/routers/post";

const scheme = new ColorScheme();
scheme.from_hue(21).scheme("triade").variation("soft");
const colors: string[] = scheme.colors();

const font = '"Nunito Sans", sans-serif';

const initialize_uplot = (
  container: HTMLDivElement,
  PTs: PT[],
  width: number,
  height: number,
) => {
  const opts = {
    width,
    height,
    // cursor: {
    //   drag: {
    //     setScale: false,
    //   },
    // },
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
    axes: [
      { font, labelFont: font },
      {
        label: "Vaccinations",
        font,
        labelFont: font,
        show: true,
        grid: { show: true },
      },
    ],
  };
  container.innerHTML = "";
  return new uPlot(opts, [], container);
};

export default function Plot({
  PTs,
  data,
  records,
  start,
  stop,
}: {
  PTs: PT[];
  data: AlignedData;
  records: number;
  start?: number;
  stop?: number;
}) {
  const graph_container = useRef<HTMLDivElement>(null);
  const parent_container = useRef<HTMLDivElement>(null);
  const ref = useRef<{ plot: uPlot | null }>({ plot: null });

  useEffect(() => {
    const resize = () => {
      if (graph_container.current && parent_container.current) {
        const rect = parent_container.current.getBoundingClientRect();

        if (!ref.current.plot) {
          ref.current.plot = initialize_uplot(
            graph_container.current,
            PTs,
            rect.width,
            rect.height * 0.65,
          );
        } else {
          ref.current.plot.setSize({
            width: rect.width,
            height: rect.height * 0.65,
          });
        }
      }
    };
    window.addEventListener("resize", resize);
    setTimeout(resize, 100);
    return () => {
      window.removeEventListener("resize", resize);
    };
  }, [PTs]);

  const play = useCallback(
    (position: number, window: number, data: AlignedData, plot: uPlot) => {
      if (data.length > 0) {
        if (Array.isArray(data[0]) && data[0].length > position) {
          // const sp = data[0][position];
          // const ep = data[0][Math.min(position + window, data[0].length - 1)];
          // const start = sp ? new Date(sp * 1000).toLocaleDateString() : "N/A";
          // const end = ep ? new Date(ep * 1000).toLocaleDateString() : "N/A";
          // console.debug(`Playing from ${start} to ${end}`);
          plot.setData(
            data.map((d) =>
              d.slice(position, position + window),
            ) as AlignedData,
          );
        }
      }
    },
    [],
  );

  useEffect(() => {
    const setData = (d: AlignedData) => {
      if (!ref.current.plot) {
        setTimeout(() => setData(d), 200);
        return;
      }
      const X = d[0];
      if (ref.current.plot && Array.isArray(X)) {
        let s = 0;
        if (typeof start === "number") {
          for (let x = 0; x < X.length; x += 1) {
            const e = X[x];
            if (e && e <= start) {
              s = x;
            } else break;
          }
        }
        let w = X.length - 1;
        if (typeof stop === "number") {
          for (let x = 0; x < X.length; x += 1) {
            const e = X[x];
            if (e && e <= stop) {
              w = x;
            } else break;
          }
        }

        play(s, w - s, d, ref.current.plot);
      }
    };
    setData(data);
  }, [data, records, start, stop]);

  return (
    <div ref={parent_container} className="flex flex-1 flex-col">
      <div ref={graph_container} className="absolute flex-1 overflow-hidden" />
    </div>
  );
}
