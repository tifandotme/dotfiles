# Agent automation for Expo apps

Research date: 2026-10-30.

## Recommendation

Use [agent-device](https://docs.expo.dev/agents/agent-device/) for native Expo development. Its CLI resembles the existing agent-browser workflow: open the app, take an accessibility snapshot, act on an element reference, and inspect a screenshot. It works with an installed development build or Expo Go, without an app dependency. Keep agent-browser for Expo's web target, if the project supports web. Web rendering does not verify native behavior.

For repeatable end-to-end tests, consider [Maestro](https://docs.expo.dev/eas/workflows/examples/e2e-tests/). It is a separate test runner, not a prerequisite for agent-device. Expo also documents [Argent](https://docs.expo.dev/agents/argent/), an MCP-based alternative for simulator automation and debugging.

## Existing setup

- The dotfiles install agent-browser through `run_onchange_02_install-bun.sh.tmpl`. Shared agent instructions require task-scoped browser sessions and project-specific Electron instructions.
- AquaSense is an Electron app. Its `dev:agent-browser` script starts Electron with `--remote-debugging-port=9232`, and its `AGENTS.md` tells agents to connect the `aquasense` session to that port. This works because Electron's renderer is Chromium; it does not make a native React Native screen a browser page.
- The installed agent-browser `0.38.1` also lists an iOS provider, but its help describes opening a URL in the iOS Simulator. That is browser automation, not evidence that it can drive a native Expo app.
- On `box`, Node is `v24.22.1`. `agent-device`, `adb`, `emulator`, `maestro`, `java`, and `xcrun` were not on PATH during the check. No `/dev/kvm` or `$HOME/Android/Sdk` was found. An Android emulator has not been configured or tested here.

## Native development loop

Install agent-device using the existing Bun global-package mechanism if adopting it across machines. The CLI requires Node 22.12 or newer. Install Android SDK tools and configure an emulator for Android; an iOS Simulator requires macOS and Xcode. See the [installation requirements](https://oss.callstack.com/agent-device/docs/installation) and [Expo Android setup](https://docs.expo.dev/workflow/android-studio-emulator/).

In an Expo project, start the development server and open the project in Expo Go or an installed development build. Expo also documents `npx expo run:android` and `npx expo run:ios` for building and running development builds. Then the agent can use the [documented device workflow](https://docs.expo.dev/agents/agent-device/):

```sh
agent-device doctor
agent-device help workflow
agent-device apps --platform ios
agent-device open MyApp --platform ios
agent-device snapshot -i
agent-device press @e2 --settle
agent-device screenshot ./artifacts/screen.png
agent-device close
```

Replace `ios` and `MyApp` with the target and installed app. The element reference comes from the current snapshot; do not reuse the example reference blindly. In Expo Go, the installed host is Expo Go, and the project must already be open in it. Use accessibility labels, roles, and test IDs for reliable targeting. Native profiling in Expo Go measures the Expo Go host; use a development build to profile app-specific native code.

The official agent-device skill is optional. The CLI exposes its own version-matched help and an optional MCP server, so a terminal-capable agent does not need MCP to start. [Expo's guide](https://docs.expo.dev/agents/agent-device/) covers the skill, MCP configuration, screenshots, logs, and React Native debugging.

## Where the simulator runs

The agent and its device can run on the same Mac. An agent running on `box` can instead connect to an agent-device proxy on a Mac with Xcode and a simulator. The [remote proxy](https://oss.callstack.com/agent-device/docs/remote-proxy) requires a reachable endpoint and a bearer token that grants device control; keep the token secret. Metro must also be reachable from the app. This cross-machine setup has not been tested here.

An Android emulator on `box` is another option, subject to installing the SDK and confirming host virtualization and headless emulator support. A physical Android device can also be automated with ADB, subject to pairing and connectivity. [Expo Simulators](https://docs.expo.dev/preview/simulators/introduction/) can provide a remote iOS or Android device, but is a limited-access preview for select partners and is not included with free or paid plans. Sessions consume billed usage and must be stopped when finished.

## Expo MCP

[Expo MCP](https://docs.expo.dev/mcp/) can supplement device automation with Expo documentation, EAS, and local app tools. Local automation requires SDK 54 or later, the `expo-mcp` development dependency, Expo CLI and remote MCP authentication with the same Expo account, and `EXPO_UNSTABLE_MCP_SERVER=1 npx expo start`. Reconnect the MCP client when the server starts or stops. Expo documents a single development-server connection at a time, and local iOS automation requires a Mac simulator. Local screenshots and other local data are proxied through Expo's remote server, so check project data rules before enabling it.

## Web target

If the app supports web, run `npx expo start --web` and use the existing task-scoped agent-browser session on the dev server URL. The [Expo web guide](https://docs.expo.dev/workflow/web/) lists the web dependencies. React Native for Web renders browser components, so native navigation, permissions, hardware, and platform-specific layout still need device checks.
