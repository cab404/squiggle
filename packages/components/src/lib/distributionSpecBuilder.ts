import { VisualizationSpec } from "react-vega";
import type { LogScale, LinearScale, PowScale, TimeScale } from "vega";

export type DistributionChartSpecOptions = {
  /** Set the x scale to be logarithmic by deault */
  logX: boolean;
  /** Set the y scale to be exponential by deault */
  expY: boolean;
  /** The minimum x coordinate shown on the chart */
  minX?: number;
  /** The maximum x coordinate shown on the chart */
  maxX?: number;
  /** The title of the chart */
  title?: string;
  /** The formatting of the ticks */
  format?: string;
  /** Whether the x-axis should be dates or numbers */
  xAxisType?: "number" | "dateTime";
};

/** X Scales */
export const linearXScale: LinearScale = {
  name: "xscale",
  clamp: true,
  type: "linear",
  range: "width",
  zero: false,
  nice: false,
  domain: { data: "domain", field: "x" },
};

export const logXScale: LogScale = {
  name: "xscale",
  type: "log",
  range: "width",
  zero: false,
  base: 10,
  nice: false,
  clamp: true,
  domain: { data: "domain", field: "x" },
};

export const timeXScale: TimeScale = {
  name: "xscale",
  clamp: true,
  type: "time",
  range: "width",
  nice: false,
  domain: { data: "domain", field: "x" },
};

/** Y Scales */
export const linearYScale: LinearScale = {
  name: "yscale",
  type: "linear",
  range: "height",
  zero: true,
  domain: { data: "domain", field: "y" },
};

export const expYScale: PowScale = {
  name: "yscale",
  type: "pow",
  exponent: 0.1,
  range: "height",
  zero: true,
  nice: false,
  domain: { data: "domain", field: "y" },
};

export const defaultTickFormat = ".9~s";
export const timeTickFormat = "%b %d, %Y %H:%M";
const width = 500;

export function buildVegaSpec(
  specOptions: DistributionChartSpecOptions
): VisualizationSpec {
  const { title, minX, maxX, logX, expY, xAxisType = "number" } = specOptions;

  const dateTime = xAxisType === "dateTime";

  // some fallbacks
  const format = specOptions?.format
    ? specOptions.format
    : dateTime
    ? timeTickFormat
    : defaultTickFormat;

  let xScale = dateTime ? timeXScale : logX ? logXScale : linearXScale;

  if (minX !== undefined && Number.isFinite(minX)) {
    xScale = { ...xScale, domainMin: minX };
  }

  if (maxX !== undefined && Number.isFinite(maxX)) {
    xScale = { ...xScale, domainMax: maxX };
  }

  const spec: VisualizationSpec = {
    $schema: "https://vega.github.io/schema/vega/v5.json",
    description: "Squiggle plot chart",
    width: width,
    height: 100,
    padding: 5,
    data: [{ name: "data" }, { name: "domain" }, { name: "samples" }],
    signals: [
      {
        name: "hover",
        value: null,
        on: [
          { events: "mouseover", update: "datum" },
          { events: "mouseout", update: "null" },
        ],
      },
      {
        name: "position",
        value: "[0, 0]",
        on: [
          { events: "mousemove", update: "xy() " },
          { events: "mouseout", update: "null" },
        ],
      },
      {
        name: "position_scaled",
        value: null,
        update: "isArray(position) ? invert('xscale', position[0]) : ''",
      },
    ],
    scales: [
      xScale,
      expY ? expYScale : linearYScale,
      {
        name: "color",
        type: "ordinal",
        domain: {
          data: "data",
          field: "name",
        },
        range: { scheme: "blues" },
      },
    ],
    axes: [
      {
        orient: "bottom",
        scale: "xscale",
        labelColor: "#727d93",
        tickColor: "#fff",
        tickOpacity: 0.0,
        domainColor: "#fff",
        domainOpacity: 0.0,
        format: format,
        tickCount: dateTime ? 3 : 10,
        labelOverlap: "greedy",
      },
    ],
    marks: [
      {
        name: "all_distributions",
        type: "group",
        from: {
          facet: {
            name: "distribution_facet",
            data: "data",
            groupby: ["name"],
          },
        },
        marks: [
          {
            name: "continuous_distribution",
            type: "group",
            from: {
              facet: {
                name: "continuous_facet",
                data: "distribution_facet",
                field: "continuous",
              },
            },
            encode: {
              update: {},
            },
            marks: [
              {
                name: "continuous_area",
                type: "area",
                from: {
                  data: "continuous_facet",
                },
                encode: {
                  update: {
                    interpolate: { value: "linear" },
                    x: {
                      scale: "xscale",
                      field: "x",
                    },
                    y: {
                      scale: "yscale",
                      field: "y",
                    },
                    fill: {
                      scale: "color",
                      field: { parent: "name" },
                    },
                    y2: {
                      scale: "yscale",
                      value: 0,
                    },
                    fillOpacity: {
                      value: 1,
                    },
                  },
                },
              },
            ],
          },
          {
            name: "discrete_distribution",
            type: "group",
            from: {
              facet: {
                name: "discrete_facet",
                data: "distribution_facet",
                field: "discrete",
              },
            },
            marks: [
              {
                type: "rect",
                from: {
                  data: "discrete_facet",
                },
                encode: {
                  enter: {
                    width: {
                      value: 1,
                    },
                  },
                  update: {
                    x: {
                      scale: "xscale",
                      field: "x",
                    },
                    y: {
                      scale: "yscale",
                      field: "y",
                    },
                    y2: {
                      scale: "yscale",
                      value: 0,
                    },
                    fill: {
                      scale: "color",
                      field: { parent: "name" },
                    },
                  },
                },
              },
              {
                type: "symbol",
                from: {
                  data: "discrete_facet",
                },
                encode: {
                  enter: {
                    shape: {
                      value: "circle",
                    },
                    size: [{ value: 100 }],
                    tooltip: {
                      signal: dateTime
                        ? "{ probability: datum.y, value: datetime(datum.x) }"
                        : "{ probability: datum.y, value: datum.x }",
                    },
                  },
                  update: {
                    x: {
                      scale: "xscale",
                      field: "x",
                      offset: 0.5, // if this is not included, the circles are slightly left of center.
                    },
                    y: {
                      scale: "yscale",
                      field: "y",
                    },
                    fill: {
                      scale: "color",
                      field: { parent: "name" },
                    },
                  },
                },
              },
            ],
          },
        ],
      },

      {
        name: "sampleset",
        type: "rect",
        from: { data: "samples" },
        encode: {
          enter: {
            x: { scale: "xscale", field: "data" },
            width: { value: 0.1 },

            y: { value: 25, offset: { signal: "height" } },
            height: { value: 5 },
          },
        },
      },
      {
        type: "text",
        name: "announcer",
        interactive: false,
        encode: {
          enter: {
            x: { signal: String(width), offset: 1 }, // vega would prefer its internal ` "width" ` variable, but that breaks the squiggle playground. Just setting it to the same var as used elsewhere in the spec achieves the same result.
            fill: { value: "black" },
            fontSize: { value: 20 },
            align: { value: "right" },
          },
          update: {
            text: {
              signal: dateTime
                ? "position_scaled ? utcyear(position_scaled) + '-' + utcmonth(position_scaled) + '-' + utcdate(position_scaled) + 'T' + utchours(position_scaled)+':' +utcminutes(position_scaled) : ''"
                : "position_scaled ? format(position_scaled, ',.4r')  : ''",
            },
          },
        },
      },
      {
        type: "rule",
        interactive: false,
        encode: {
          enter: {
            x: { value: 0 },
            y: { scale: "yscale", value: 0 },

            y2: {
              signal: "height",
              offset: 2,
            },
            strokeDash: { value: [5, 5] },
          },

          update: {
            x: {
              signal:
                "position ? position[0] < 0 ? null : position[0] > width ? null : position[0]: null",
            },

            opacity: {
              signal:
                "position ? position[0] < 0 ? 0 : position[0] > width ? 0 : 1 : 0",
            },
          },
        },
      },
    ],
    legends: [
      {
        fill: "color",
        orient: "top",
        labelFontSize: 12,
        encode: {
          symbols: {
            update: {
              fill: [
                { test: "length(domain('color')) == 1", value: "transparent" },
                { scale: "color", field: "value" },
              ],
            },
          },
          labels: {
            interactive: true,
            update: {
              fill: [
                { test: "length(domain('color')) == 1", value: "transparent" },
                { value: "black" },
              ],
            },
          },
        },
      },
    ],
    ...(title && {
      title: {
        text: title,
      },
    }),
  };

  return spec;
}
