# frozen_string_literal: true

require "fusuma/device"
require "fusuma/multi_logger"

module Fusuma
  module Plugin
    module Inputs
      # Read pointing stick events
      class Hidraw
        class Device
          # Definitions of IOCTL commands
          HIDIOCGRAWNAME = 0x80804804
          HIDIOCGRAWPHYS = 0x80404805
          HIDIOCGRAWINFO = 0x80084803
          HIDIOCGRDESCSIZE = 0x80044801
          HIDIOCGRDESC = 0x90044802

          # Definitions of bus types
          BUS_PCI = 0x01
          BUS_ISAPNP = 0x02
          BUS_USB = 0x03
          BUS_HIL = 0x04
          BUS_BLUETOOTH = 0x05
          BUS_VIRTUAL = 0x06

          attr_reader :hidraw_path, :name, :bustype, :vendor_id, :product_id

          def initialize(hidraw_path:)
            @hidraw_path = hidraw_path
            load_device_info
          end

          private

          def load_device_info
            File.open(@hidraw_path, "rb+") do |file|
              @name = fetch_ioctl_data(file, HIDIOCGRAWNAME).strip

              info = fetch_ioctl_data(file, HIDIOCGRAWINFO, [0, 0, 0].pack("LSS"))
              @bustype, vendor, product = info.unpack("LSS")
              @vendor_id = vendor.to_s(16)
              @product_id = product.to_s(16)
            end
          rescue => e
            MultiLogger.error "Error loading device info: #{e.message}"
          end

          def fetch_ioctl_data(file, ioctl_command, buffer = " " * 256)
            file.ioctl(ioctl_command, buffer)
            buffer
          rescue Errno::EIO
            MultiLogger.warn "Failed to retrieve data with IOCTL command #{ioctl_command}, the device might not support this operation."
          end
        end

        class DeviceFinder
          def find(device_name_pattern)
            device_name_pattern = Regexp.new(device_name_pattern) if device_name_pattern.is_a?(String)
            event_path = find_pointer_device_path(device_name_pattern)
            return nil unless event_path

            hidraw_path = find_hidraw_path(event_path)

            return Device.new(hidraw_path: hidraw_path) if hidraw_path

            nil
          end

          private

          def find_hidraw_path(event_path)
            event_abs_path = File.realpath(event_path)
            parent_path = event_abs_path.gsub(%r{/input/input\d+/.*}, "")
            locate_hidraw_device(parent_path)
          end

          def find_pointer_device_path(device_name_pattern)
            Fusuma::Device.reset

            device = Fusuma::Device.all.find do |device|
              device.name =~ device_name_pattern && device.capabilities == "pointer"
            end

            device&.then { |d| "/sys/class/input/#{d.id}" }
          end

          def locate_hidraw_device(parent_path)
            Dir.glob("#{parent_path}/hidraw/hidraw*").find do |path|
              if File.exist?(path)
                hidraw_device_path = path.gsub(%r{^/.*hidraw/hidraw}, "/dev/hidraw")
                return hidraw_device_path if File.readable?(hidraw_device_path)
              end
            end

            nil
          end
        end
      end
    end
  end
end
