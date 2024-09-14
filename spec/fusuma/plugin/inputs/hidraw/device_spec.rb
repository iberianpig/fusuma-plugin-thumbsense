require "spec_helper"
require "fusuma/plugin/inputs/hidraw/device"

module Fusuma::Plugin::Inputs
  RSpec.describe Hidraw::Device do
    let(:hidraw_path) { "/dev/hidraw0" }
    let(:device) { described_class.new(hidraw_path: hidraw_path) }

    before do
      allow(File).to receive(:open).with(hidraw_path, "rb+").and_yield(double(ioctl: true))
    end

    describe "#initialize" do
      it "sets the hidraw_path" do
        expect(device.hidraw_path).to eq(hidraw_path)
      end

      it "loads device info" do
        device_name = "Test Device"

        # struct hidraw_devinfo {
        #     __u32 bustype;
        #     __s16 vendor;
        #     __s16 product;
        # };
        hidraw_definfo = [
          0x03, # BUS_USB
          0x1234,
          0x5678
        ].pack("LSS")

        allow_any_instance_of(described_class).to receive(:fetch_ioctl_data)
          .with(anything, described_class::HIDIOCGRAWNAME)
          .and_return(device_name)

        allow_any_instance_of(described_class).to receive(:fetch_ioctl_data)
          .with(anything, described_class::HIDIOCGRAWINFO, anything)
          .and_return(hidraw_definfo)

        expect(device.name).to eq("Test Device")
        expect(device.bustype).to eq(described_class::BUS_USB)
        expect(device.vendor_id).to eq("1234")
        expect(device.product_id).to eq("5678")
      end
    end
  end
end
