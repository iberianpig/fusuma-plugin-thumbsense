# Fusuma::Plugin::Thumbsense [![Gem Version](https://badge.fury.io/rb/fusuma-plugin-thumbsense.svg)](https://badge.fury.io/rb/fusuma-plugin-thumbsense) [![Build Status](https://github.com/iberianpig/fusuma-plugin-thumbsense/actions/workflows/ubuntu.yml/badge.svg)](https://github.com/iberianpig/fusuma-plugin-thumbsense/actions/workflows/ubuntu.yml)


Keyboard + Touchpad combination plugin for [Fusuma](https://github.com/iberianpig/fusuma)

* Customize gestures with modifier keys
* Supports multiple modifier key combinations

## Installation

Run the following code in your terminal.

### Install fusuma-plugin-thumbsense

This plugin requires [Fusuma](https://github.com/iberianpig/fusuma#update) version 1.4 or later.

```sh
$ sudo gem install fusuma-plugin-thumbsense
```

### Add show-keycodes option

Open `~/.config/fusuma/config.yml` and add the following code at the bottom.

```yaml
plugin:
  inputs:
    libinput_command_input:
      show-keycodes: true
```

**NOTE: fusuma can read your keyboard inputs if show-keycodes option is true**

## Properties

### Thumbsense
Add `thumbsense:` property in `~/.config/fusuma/config.yml`.

Keys following are available for `thumbsense`.

* `CAPSLOCK`
* `LEFTALT`
* `LEFTCTRL`
* `LEFTMETA`
* `LEFTSHIFT`
* `RIGHTALT`
* `RIGHTCTRL`
* `RIGHTSHIFT`
* `RIGHTMETA`

## Example

Set `thumbsense:` property and values under gesture in `~/.config/fusuma/config.yml`.

```yaml
thumbsense:
  keypress:
   touchpad:
     f: left-click
     j: left-click
     j: right-click

swipe:
  4:
    up:
      command: 'xdotool key super+s'
      thumbsense:
        LEFTMETA:
          command: 'xdotool key --clearmodifiers XF86MonBrightnessUp'
        LEFTMETA+LEFTALT:
          command: 'xdotool key --clearmodifiers XF86AudioRaiseVolume'

    down:
      command: 'xdotool key super+a'
      thumbsense:
        LEFTMETA:
          command: 'xdotool key --clearmodifiers XF86MonBrightnessDown'
        LEFTMETA+LEFTALT:
          command: 'xdotool key --clearmodifiers XF86AudioLowerVolume'

plugin:
  inputs:
    libinput_command_input:
      show-keycodes: true
```

* Swipe up/down with four fingers while thumbsense LEFTMETA key to change display brightnes .
* Swipe up/down with four fingers while thumbsense LEFTMETA and LEFTALT keys to change audio volume.
  - If you want to combine a gesture with two keys, combine modifier keys with `+`




## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iberianpig/fusuma-plugin-thumbsense. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fusuma::Plugin::Thumbsense project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/iberianpig/fusuma-plugin-thumbsense/blob/master/CODE_OF_CONDUCT.md).
