# M1DDCControl

A minimal macOS menu bar app for controlling **external monitor brightness** using [`m1ddc`](https://github.com/waydabber/m1ddc) on Apple Silicon Macs.

## Features

- Menu bar app using SwiftUI
- Controls brightness for external displays supported by `m1ddc`
- Shows all detected displays, including the built-in Retina display
- Built-in Retina display is visible but read-only
- Brightness slider with manual **Set Brightness** action
- **Load at startup** toggle
- **Quit** button in the popup
- Display list shown in the output box for quick reference

## Notes

- This app is designed for **external displays**.
- The built-in Retina display is shown in the list, but brightness control is disabled for it.
- `Get Brightness` was intentionally removed because some monitors return unreliable `0` values through DDC read operations.
- The output box is used only to show the display list.

## Requirements

- macOS 13 or later
- Apple Silicon Mac
- Homebrew
- `m1ddc`

## Install `m1ddc`

```bash
brew install m1ddc