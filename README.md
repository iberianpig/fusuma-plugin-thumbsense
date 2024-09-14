# Fusuma::Plugin::Thumbsense [![Gem Version](https://badge.fury.io/rb/fusuma-plugin-thumbsense.svg)](https://badge.fury.io/rb/fusuma-plugin-thumbsense) [![Build Status](https://github.com/iberianpig/fusuma-plugin-thumbsense/actions/workflows/main.yml/badge.svg)](https://github.com/iberianpig/fusuma-plugin-thumbsense/actions/workflows/main.yml)

Remapper from key to click only while tapping the touchpad.  
Implemented as [Fusuma](https://github.com/iberianpig/fusuma) Plugin.

## What is ThumbSense?
[ThumbSense](https://www2.sonycsl.co.jp/person/rekimoto/tsense/soft/index.html) is a tool that lets you control a laptop's touchpad using the keyboard. It assigns certain keyboard keys as mouse buttons and switches between acting as mouse buttons or normal keyboard keys based on whether the user's thumb is touching the touchpad. ThumbSense aims to make it easier to use the touchpad without moving your hand away from the keyboard.

## Installation

### Prerequisites

- [fusuma](https://github.com/iberianpig/fusuma#update)  2.0 or later
- [fusuma-plugin-keypress](https://github.com/iberianpig/fusuma-plugin-keypress) 0.5 or later (automatically installed)
- [fusuma-plugin-remap](https://github.com/iberianpig/fusuma-plugin-remap) (udev rules setup required)

### Steps to Install and Set Up Fusuma::Plugin::Thumbsense

1. Install the necessary packages for native extensions:
```sh
$ sudo apt install ruby-dev build-essential
```

2. Install the required library for building fusuma-plugin-remap:
```sh
$ sudo apt install libevdev-dev
```

3. Set up udev rules to create a virtual input device (for fusuma-plugin-remap):
```sh
$ echo 'KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/60-udev-fusuma-remap.rules
$ sudo udevadm control --reload-rules && sudo udevadm trigger
```

4. Install fusuma-plugin-thumbsense:
```sh
$ sudo gem install fusuma-plugin-thumbsense
```

## Configuration

### Thumbsense Context

To add the thumbsense `context`, edit `~/.config/fusuma/config.yml`.
The `context` section is separated by `---` and specified as `context: thumbsense`.
Fusuma will switch to the `thumbsense` context while tapping the touchpad.

### Key to Mouse Button Remap

You can remap keys to mouse buttons while tapping the touchpad.
The `remap` property is configured within the `thumbsense` context.

Available mouse buttons include:
- `BTN_LEFT`
- `BTN_MIDDLE`
- `BTN_RIGHT`
- `BTN_SIDE`
- `BTN_EXTRA`
- `BTN_FORWARD`
- `BTN_BACK`
- `BTN_TASK`
- `BTN_0`
- `BTN_1`
-   ...
- `BTN_9`

### Example Configuration

Add the following code to `~/.config/fusuma/config.yml`:

```yaml
# Add thumbsense context
---
context: thumbsense

remap:
  F: BTN_LEFT
  E: BTN_MIDDLE
  D: BTN_RIGHT
  SPACE: BTN_LEFT
  J: BTN_LEFT
  K: BTN_RIGHT
```

## Pointing Stick Support

### Overview
Fusuma::Plugin::Thumbsense provides experimental support for pointing stick devices. This functionality is currently limited to the **HHKB Studio** and utilizes HIDRAW. Please note that this feature is still in testing, and improvements may be made in future updates.

see: https://github.com/iberianpig/fusuma-plugin-thumbsense/pull/4

### Setting Up Udev Rules

To use the pointing stick touch support, you need to set up the following Udev rules to ensure that the HHKB Studio device is correctly recognized:

1. **Create the Udev Rule File**:
   Create a Udev rule file with the following command:

   ```sh
   sudo nano /etc/udev/rules.d/60-udev-fusuma-thumbsense-hhkb-studio.rules
   ```

   Add the following content to the file:

   ```plaintext
   # HHKB Studio (USB)
   KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="04fe", ATTRS{idProduct}=="0016", MODE="0666"
   
   # HHKB Studio (Bluetooth)
   KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ENV{DEVPATH}=="/devices/virtual/misc/uhid/*:04FE:0016.*/hidraw*", MODE="0666"
   ```

2. **Reload the Udev Rules**:
   Execute the following command to reload the Udev rules:

   ```sh
   sudo udevadm control --reload-rules && sudo udevadm trigger
   ```

## TODO LIST

- ThumbSense
  - [x] Change remap layer while tapping
  - [x] Enable executing commands like `command:` and `sendkey:`
  - [x] Support pointing stick devices(https://github.com/iberianpig/fusuma-plugin-thumbsense/pull/4)
    - Now only HHKB Studio is supported using HIDRAW

- Remap
  - [x] Remap to single key (e.g., `remap: { J: BTN_LEFT }`)
  - [x] Send mouse clicks with `remap: { I: BTN_MIDDLE }`
  - [x] Remap multiple keys
    - Support sending multiple keys with fusuma-plugin-sendkey(https://github.com/iberianpig/fusuma-plugin-sendkey/pull/34)
      - `remap: { T: { sendkey: [LEFTSHIFT+F10, T, ENTER, ESC] } }`
  - [ ] Remap POINTER_MOTION to POINTER_SCROLL_FINGER (e.g., `remap: { S: POINTER_SCROLL_FINGER }`)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iberianpig/fusuma-plugin-thumbsense. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fusuma::Plugin::Thumbsense project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/iberianpig/fusuma-plugin-thumbsense/blob/master/CODE_OF_CONDUCT.md).
