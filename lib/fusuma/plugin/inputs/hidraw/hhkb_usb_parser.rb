# frozen_string_literal: true

module Fusuma
  module Plugin
    module Inputs
      class Hidraw
        class HhkbUsbParser
          BASE_TIMEOUT = 0.03  # Base timeout value for reading reports
          MAX_TIMEOUT = 0.2    # Maximum timeout value before failure
          MULTIPLIER = 1.1     # Multiplier to exponentially increase timeout

          MAX_REPORT_SIZE = 5  # Maximum report size in bytes

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
                  # instance.parse_hid_report(report_bytes)
                  case mouse_state
                  when :begin, :update
                    :update
                  else
                    :begin
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
            return :end if report_bytes.nil?

            # buttons, x, y, wheel, ac_pan = report_bytes.unpack("Ccccc") # Retrieve 5-byte report
            # - `C`: 1 byte unsigned integer (button state) (0..255)
            # - `c`: 1 byte signed integer (X-axis) (-127..127)
            # - `c`: 1 byte signed integer (Y-axis) (-127..127)
            # - `c`: 1 byte signed integer (Wheel) (-127..127)
            # - `c`: 1 byte signed integer (AC pan) (-127..127)
            # button_states = buttons.to_s(2).rjust(8, "0").chars.map(&:to_i)

            # puts "Raw bytes: #{report_bytes.inspect}" # Display raw byte sequence
            # puts "# Button: #{button_states.join(" ")} | X: #{x.to_s.rjust(4)} | Y: #{y.to_s.rjust(4)} | Wheel: #{wheel.to_s.rjust(4)} | AC Pan: #{ac_pan.to_s.rjust(4)}"

            :begin
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
  if device.bustype == Fusuma::Plugin::Inputs::Hidraw::Device::BUS_USB
    Fusuma::Plugin::Inputs::Hidraw::HhkbUsbParser.new(device).parse do |state|
      puts "Touch state: #{state}"
    end
  else
    puts "Bustype is not USB"
  end
end
