# SubStat

A lightweight macOS menubar app that monitors your VLESS subscription usage in real-time.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Menubar Display** — See remaining days and data at a glance
- **Detailed Popup** — Click to view total, downloaded, uploaded, remaining data with progress bars
- **Auto Refresh** — Configurable refresh interval (10m, 30m, 1h, or manual)
- **Customizable** — Choose what to display in the menubar (days, GB, or both)
- **Launch at Login** — Start automatically when you log in
- **Native macOS** — Built with SwiftUI, zero dependencies, lightweight

## Screenshots

*Coming soon*

## Requirements

- macOS 13.0 (Ventura) or later
- A VLESS subscription URL from X-UI / 3X-UI panel

## Installation

### Download

Download the latest release from the [Releases](https://github.com/AmirhpCom/SubStat/releases) page.

### Build from Source

1. Clone the repository
2. Open `SubStat.xcodeproj` in Xcode 15+
3. Build and run (Cmd+R)

## Usage

1. Launch SubStat — it appears in your menubar
2. Click the menubar item to see detailed subscription info
3. Click **Settings** (or Cmd+,) to configure:
   - Paste your subscription URL
   - Set a custom name
   - Choose refresh interval
   - Customize menubar display

## How It Works

SubStat fetches your subscription page and reads the usage data from the HTML response. It supports X-UI and 3X-UI panels that provide subscription data via the `<template id="subscription-data">` element.

## Developer

**AmirhpCom**

## License

MIT License — see [LICENSE](LICENSE) for details.
