// @ts-check

/**
 * @typedef {import("/Applications/Finicky.app/Contents/Resources/finicky.d.ts").FinickyConfig} FinickyConfig
 */

/** @type {FinickyConfig} */
export default {
  defaultBrowser: "/Applications/Helium.app",
  handlers: [
    {
      match: "*.hadl.ai*",
      browser: "net.imput.helium.work",
    },
    {
      match: (url) => url.hostname === "hadlworkspace.slack.com",
      browser: "net.imput.helium.work",
    },
    {
      match: (url) =>
        url.hostname === "github.com" &&
        (url.pathname === "/hadl-labs" || url.pathname.startsWith("/hadl-labs/")),
      browser: "net.imput.helium.work",
    },
    {
      match: (_url, { opener }) => opener?.bundleId === "com.tinyspeck.slackmacgap",
      browser: "net.imput.helium.work",
    },
  ],
};
