# frozen_string_literal: true

require "spec_helper"

require "fusuma/plugin/inputs/input"
require "fusuma/plugin/inputs/pointing_stick_input"
require "stringio"

module Fusuma
  module Plugin
    module Inputs
      # Simple dummy parser class
      class Hidraw::DummyParser
        def initialize(device)
        end

        def parse
          yield "s1"
          yield "s1"
          yield "s2"
        end
      end

      RSpec.describe PointingStickInput do
        let(:pattern) { "MyDevice" }

        subject(:input) do
          allow_any_instance_of(described_class)
            .to receive(:config_params).with(:device_name_pattern).and_return(pattern)
          described_class.new
        end

        describe "#config_param_types" do
          it "defines device_name_pattern as String" do
            expect(subject.config_param_types).to eq(device_name_pattern: String)
          end
        end

        describe "#select_hidraw_parser" do
          it "returns HhkbUsbParser for USB bus" do
            expect(
              subject.send(:select_hidraw_parser, Hidraw::Device::BUS_USB)
            ).to eq Hidraw::HhkbUsbParser
          end

          it "returns HhkbBluetoothParser for Bluetooth bus" do
            expect(
              subject.send(:select_hidraw_parser, Hidraw::Device::BUS_BLUETOOTH)
            ).to eq Hidraw::HhkbBluetoothParser
          end

          it "exits the process for unsupported bus types" do
            expect(MultiLogger).to receive(:error)
              .with("Unsupported bus type: 999")
            expect { subject.send(:select_hidraw_parser, 999) }
              .to raise_error(SystemExit)
          end
        end

        describe "#find_hidraw_device" do
          let(:fake_finder) { instance_double(Hidraw::DeviceFinder) }
          let(:fake_device) { double("Device") }

          before do
            allow(Hidraw::DeviceFinder).to receive(:new).and_return(fake_finder)
            # Skip sleep for immediate response
            allow(subject).to receive(:sleep)
          end

          context "when the device is found immediately" do
            before do
              allow(fake_finder).to receive(:find).with(pattern).and_return(fake_device)
              expect(MultiLogger).to receive(:info)
                .with("Found pointing stick device: #{pattern}")
            end

            it "returns the device immediately" do
              expect(
                subject.send(:find_hidraw_device, pattern, wait: 1)
              ).to eq(fake_device)
            end
          end

          context "when not found at first but found on retry" do
            before do
              calls = [nil, fake_device]
              allow(fake_finder).to receive(:find).with(pattern) { calls.shift }
              expect(MultiLogger).to receive(:warn)
                .with("No pointing stick device found: #{pattern}")
              expect(MultiLogger).to receive(:info)
                .with("Found pointing stick device: #{pattern}")
            end

            it "returns the device after retrying" do
              expect(
                subject.send(:find_hidraw_device, pattern, wait: 0)
              ).to eq(fake_device)
            end
          end
        end

        describe "#read_from_io" do
          let(:line) { "foo_state\n" }

          before do
            # Mock io with StringIO
            fake_io = StringIO.new(line)
            allow(subject).to receive(:io).and_return(fake_io)
          end

          it "returns a correct GestureRecord" do
            record = subject.read_from_io
            expect(record.gesture).to eq("touch")
            expect(record.status).to eq("foo_state")
            expect(record.finger).to eq(1)
            expect(record.delta).to be_nil
          end
        end

        describe "#process_device_events" do
          let(:fake_device) { double("Device", bustype: Hidraw::Device::BUS_USB) }
          let(:fake_finder) { instance_double(Hidraw::DeviceFinder) }
          let(:writer) { StringIO.new }

          before do
            allow(subject).to receive(:find_hidraw_device).and_return(fake_device)
            allow(subject).to receive(:select_hidraw_parser)
              .with(fake_device.bustype).and_return(Hidraw::DummyParser)
          end

          it "writes only state changes to writer" do
            subject.send(:process_device_events, writer)
            writer.rewind
            expect(writer.read).to eq("s1\ns2\n")
          end

          context "when pattern is not set" do
            let(:pattern) { nil }

            it "keeps blocking find_hidraw_device" do
              expect(subject).to receive(:sleep).with(no_args)
              subject.send(:process_device_events, StringIO.new)
            end
          end
        end
      end
    end
  end
end
