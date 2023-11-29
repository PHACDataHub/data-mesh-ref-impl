/**
 * Run `build` or `dev` with `SKIP_ENV_VALIDATION` to skip env validation. This is especially useful
 * for Docker builds.
 */
// import CopyPlugin from "copy-webpack-plugin";

await import("./src/env.js");


/** @type {import("next").NextConfig} */
const config = {
  reactStrictMode: true,

  /**
   * If you are using `appDir` then you must comment the below `i18n` config out.
   *
   * @see https://github.com/vercel/next.js/issues/41980
   */
  i18n: {
    locales: ["en"],
    defaultLocale: "en",
  },
  // webpack: (config) => {
  //   // Note: we provide webpack above so you should not `require` it
  //   // Perform customizations to webpack config
  //   const destWasmFolder = "static/chunks/pages";
  //   config.plugins.push(
  //     new CopyPlugin({
  //       patterns: [
  //           { from: "node_modules/scichart/_wasm/scichart2d.wasm", to: destWasmFolder },
  //       ]
  //     })
  //   );
  //   return config;
  // },
};

export default config;
