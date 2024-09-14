# frozen_string_literal: true

module Fusuma
  module Plugin
    module Inputs
      class Hidraw
        class HhkbBluetoothParser
          BASE_TIMEOUT = 0.03  # Base timeout value for reading reports
          MAX_TIMEOUT = 0.2    # Maximum timeout value before failure
          MULTIPLIER = 1.1     # Multiplier to exponentially increase timeout

          MAX_REPORT_SIZE = 9  # Maximum report size in bytes

          # @param hidraw_device [Hidraw::Device] the HID raw device
          def initialize(hidraw_device)
            @hidraw_device = hidraw_device
          end

          # Parse HID raw device events.
          def parse
            File.open(@hidraw_device.hidraw_path, "rb") do |device|
              timeout = nil

              # Continuously read reports from the device.
              while (report = read_with_timeout(device, timeout))
                mouse_state = if report.empty?
                  # Handle timeout case
                  :end
                else
                  case parse_hid_report(report)
                  when :mouse
                    case mouse_state
                    when :begin, :update
                      :update
                    else
                      :begin
                    end
                  when :keyboard
                    # Continue mouse_state when keyboard operation
                    mouse_state
                  else
                    :end
                  end
                end

                case mouse_state
                when :begin, :update
                  timeout = update_timeout(timeout)
                when :end
                  timeout = nil
                end

                yield mouse_state
              end
            end
          end

          # Reads the HID report from the device with a timeout.
          # @param device [File] the opened device file
          # @param timeout [Float] the timeout duration
          # @return [String] the HID report as bytes or an empty string on timeout
          def read_with_timeout(device, timeout)
            # puts "Timeout: #{timeout}"  # Log timeout for debugging
            Timeout.timeout(timeout) { device.read(MAX_REPORT_SIZE) }
          rescue Timeout::Error
            ""
          end

          # Update the timeout based on previous value.
          # @param timeout [Float, nil] previously set timeout
          # @return [Float] the updated timeout value
          def update_timeout(timeout)
            return BASE_TIMEOUT if timeout.nil?

            [timeout * MULTIPLIER, MAX_TIMEOUT].min
          end

          # Parse the HID report to determine its type.
          # @param report_bytes [String] the HID report as byte data
          # @return [Symbol, nil] symbol indicating type of report or nil on error
          def parse_hid_report(report_bytes)
            report_id = report_bytes.getbyte(0)
            case report_id
            when 1
              # parse_mouse_report(report_bytes)
              :mouse
            when 127
              # parse_keyboard_report(report_bytes)
              :keyboard
            else
              MultiLogger.warn "Unknown Report ID: #{report_id}"
              nil
            end
          end

          # Parse mouse report data.
          # @param report_bytes [String] the HID mouse report as byte data
          def parse_mouse_report(report_bytes)
            puts "Raw bytes: #{report_bytes.inspect}" # Display raw byte bytes

            report_id, buttons, x, y, wheel, ac_pan = report_bytes.unpack("CCcccc") # Retrieve 6-byte report
            # - `C`: 1 byte unsigned integer (report ID) (0..255)
            # - `C`: 1 byte unsigned integer (button state) (0..255)
            # - `c`: 1 byte signed integer (x-axis) (-128..127)
            # - `c`: 1 byte signed integer (y-axis) (-128..127)
            # - `c`: 1 byte signed integer (wheel) (-128..127)
            # - `c`: 1 byte signed integer (AC pan) (-128..127)
            button_states = buttons.to_s(2).rjust(8, "0").chars.map(&:to_i)

            puts "# ReportID: #{report_id} / Button: #{button_states.join(" ")} | X: #{x.to_s.rjust(4)} | Y: #{y.to_s.rjust(4)} | Wheel: #{wheel.to_s.rjust(4)} | AC Pan: #{ac_pan.to_s.rjust(4)}"
          end

          # Parse keyboard report data.
          # @param report_bytes [String] the HID keyboard report as byte data
          def parse_keyboard_report(report_bytes)
            report_id, modifiers, _reserved1, *keys = report_bytes.unpack("CCCC6") # Retrieve 9-byte report
            # - `C`: 1 byte unsigned integer (report ID) (0..255)
            # - `C`: 1 byte unsigned integer (modifier keys) (0..255)
            # - `C`: 1 byte reserved (0)
            # - `C`: 6 bytes of keycodes (0..255)
            modifier_states = %w[LeftControl LeftShift LeftAlt LeftGUI RightControl RightShift RightAlt RightGUI].map.with_index { |m, i| "#{m}: #{((modifiers & (1 << i)) != 0) ? 1 : 0}" }
            keys_output = keys.map { |key| (key == 0) ? "0x70000" : translate_keycode(key) }
            puts "# ReportID: #{report_id} / #{modifier_states.join(" | ")} | Keyboard #{keys_output}"
          end

          # Translate keycode to its string representation.
          # @param keycode [Integer] the keycode to translate
          # @return [String] the string representation of the keycode
          def translate_keycode(keycode)
            # Map of keycodes to their respective characters
            keycodes = {
              4 => "a and A", 7 => "d and D", 16 => "s and S", 19 => "w and W",
              9 => "f and F", 10 => "g and G", 14 => "j and J", 15 => "k and K",
              33 => "[ and {", 47 => "] and }"
              # Add more as needed
            }
            keycodes[keycode] || "0x#{keycode.to_s(16)}"  # Return hexadecimal if not found
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require "timeout"

  require_relative "device"
  require "fusuma/plugin/inputs/libinput_command_input"

  device = Fusuma::Plugin::Inputs::Hidraw::DeviceFinder.new.find("HHKB-Studio")
  return if device.nil?

  puts "Device: #{device.name} (#{device.vendor_id}:#{device.product_id})"
  if device.bustype == Fusuma::Plugin::Inputs::Hidraw::Device::BUS_BLUETOOTH
    Fusuma::Plugin::Inputs::Hidraw::HhkbBluetoothParser.new(device).parse do |state|
      puts "Touch state: #{state}"
    end
  else
    puts "Bustype is not BUS_BLUETOOTH"
  end
end
