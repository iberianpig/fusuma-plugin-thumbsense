# Fusuma::Plugin::Thumbsense [![Gem Version](https://badge.fury.io/rb/fusuma-plugin-thumbsense.svg)](https://badge.fury.io/rb/fusuma-plugin-thumbsense) [![Build Status](https://github.com/iberianpig/fusuma-plugin-thumbsense/actions/workflows/main.yml/badge.svg)](https://github.com/iberianpig/fusuma-plugin-thumbsense/actions/workflows/main.yml)

Remapper from key to click only while tapping the touchpad.  
Implemented as [Fusuma](https://github.com/iberianpig/fusuma) Plugin.

**THIS PLUGIN IS EXPERIMENTAL.**

## What is ThumbSense?
[ThumbSense](https://www2.sonycsl.co.jp/person/rekimoto/tsense/soft/index.html) is a tool that lets you control a laptop's touchpad using the keyboard. It assigns certain keyboard keys as mouse buttons and switches between acting as mouse buttons or normal keyboard keys based on whether the user's thumb is touching the touchpad. ThumbSense aims to make it easier to use the touchpad without moving your hand away from the keyboard.

## Installation

### Requirements

- [fusuma](https://github.com/iberianpig/fusuma#update)  2.0 or later
- [fusuma-plugin-keypress](https://github.com/iberianpig/fusuma-plugin-keypress) 0.5 or later
  - fusuma-plugin-keypress is used to get keyboard input and is installed automatically.
- [fusuma-plugin-remap](https://github.com/iberianpig/fusuma-plugin-remap)
  - You need to set up udev rules for creating a virtual input device.
  - Please refer to [fusuma-plugin-remap's README](https://github.com/iberianpig/fusuma-plugin-remap?tab=readme-ov-file#set-up-udev-rules) for details.

### Install fusuma-plugin-thumbsense

Run the following code in your terminal.

```sh
$ sudo gem install fusuma-plugin-thumbsense
```

## Properties

### Thumbsense

First, add the `thumbsense` context to `~/.config/fusuma/config.yml`.
The context is separated by `---` and specified by `context: thumbsense`.

## Example

Set the following code in `~/.config/fusuma/config.yml`.

```yaml
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

### TODO

- thumbsense
  - [x] change layer of remap while tapping
  - [ ] call executor like `command:`, `sendkey:`

- remap
  - [x] remap to single key like `remap: { J: BTN_LEFT }` 
  - [x] send BTN_LEFT/BTN_MIDDLE/BTN_RIGHT click `remap: { I: BTN_MIDDLE }`
  - [ ] remap multiple keys like `remap: { H: LEFTCTRL+TAB }`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iberianpig/fusuma-plugin-thumbsense. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fusuma::Plugin::Thumbsense project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/iberianpig/fusuma-plugin-thumbsense/blob/master/CODE_OF_CONDUCT.md).
