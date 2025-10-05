# Open source firmware for ZBMINIR2

Custom firmware for SONOFF ZBMINIR2 with support for Zigbee bindings.

Check out the wiki for [instructions](https://github.com/ius/zbminir2/wiki/Getting-started) on building the firmware and flashing. Join [Discord](https://discord.gg/nyFRZ7SYQY) if you have any feedback or questions about getting it up and running or adapting it to your use case.

## Important bits
- This firmware currently only implements functionality to send Zigbee commands to bound devices upon triggering the external switch. Other features supported by SONOFF firmware are not implemented.
- Current status: stable. It has never failed to toggle any Hue/Tradfri bulb in my 'production' environment over many months.
- Flashing the ZBMINIR2 requires disassembling the device (difficulty: _very easy_) and attaching a SWD adapter to its test points (difficulty: _medium_). This might require soldering. Future updates can be installed over-the-air.
- You **cannot revert to original firmware** because the device is locked down and the (original) firmware is encrypted with an unknown cryptographic key. Unlocking the device will also wipe the key.

## Features
- Support for **bindings** to directly toggle a Zigbee device (e.g. lightbulb) - works even when the coordinator is unavailable.
- Updates can be installed over-the-air
- 'Factory reset' by toggling the external switch ~5 times within 5 seconds.
- Supports a simple on/off switch only (ie. no pulse switch).
