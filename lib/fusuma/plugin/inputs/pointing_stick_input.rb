# frozen_string_literal: true

require "fusuma/device"

require_relative "hidraw/device"
require_relative "hidraw/hhkb_bluetooth_parser"
require_relative "hidraw/hhkb_usb_parser"

module Fusuma
  module Plugin
    module Inputs
      # Read pointing stick events
      class PointingStickInput < Input
        def config_param_types
          {
            device_name_pattern: String
          }
        end

        def initialize
          super
          @device_name_pattern = config_params(:device_name_pattern)
        end

        def io
          @io ||= begin
            reader, writer = IO.pipe
            Thread.new do
              process_device_events(writer)
              writer.close
            end

            reader
          end
        end

        def process_device_events(writer)
          # If device_name_pattern is not set, this plugin is not used, so block the thread.
          sleep if @device_name_pattern.nil?

          hidraw_device = find_hidraw_device(@device_name_pattern, wait: 3)
          hidraw_parser = select_hidraw_parser(hidraw_device.bustype)

          mouse_state = nil

          hidraw_parser.new(hidraw_device).parse do |new_state|
            # Write state to pipe only when it changes
            next if mouse_state == new_state

            mouse_state = new_state
            writer.puts(mouse_state)
          end
        rescue Errno::EIO => e
          MultiLogger.error "#{self.class.name}: #{e}"
          retry
        end

        # Override Input#read_from_io
        def read_from_io
          status = io.readline(chomp: true)
          Events::Records::GestureRecord.new(gesture: "touch", status: status, finger: 1, delta: nil)
        rescue EOFError => e
          MultiLogger.error "#{self.class.name}: #{e}"
          MultiLogger.error "Shutdown fusuma process..."
          Process.kill("TERM", Process.pid)
        end

        private

        # Retry and wait until hidraw is found
        def find_hidraw_device(device_name_pattern, wait:)
          device_finder = Hidraw::DeviceFinder.new
          logged = false
          loop do
            device = device_finder.find(device_name_pattern)
            if device
              MultiLogger.info "Found pointing stick device: #{device_name_pattern}"

              return device
            end

            MultiLogger.warn "No pointing stick device found: #{device_name_pattern}" unless logged
            logged = true

            sleep wait
          end
        end

        # Select parser based on the bus type
        # @param bustype [Integer]
        def select_hidraw_parser(bustype)
          case bustype
          when Hidraw::Device::BUS_BLUETOOTH
            Hidraw::HhkbBluetoothParser
          when Hidraw::Device::BUS_USB
            Hidraw::HhkbUsbParser
          else
            MultiLogger.error "Unsupported bus type: #{bustype}"
            exit 1
          end
        end
      end
    end
  end
end
