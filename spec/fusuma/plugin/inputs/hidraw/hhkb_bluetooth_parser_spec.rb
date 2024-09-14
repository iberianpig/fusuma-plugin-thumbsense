require "spec_helper"
require "timeout"
require "tempfile"

require "fusuma/multi_logger"
require "fusuma/plugin/inputs/hidraw/hhkb_bluetooth_parser"
require "fusuma/plugin/inputs/hidraw/device"

RSpec.describe Fusuma::Plugin::Inputs::Hidraw::HhkbBluetoothParser do
  let(:parser) { described_class.new(hidraw_device) }
  let(:hidraw_device) { double("Hidraw::Device", hidraw_path: Tempfile.new("hidraw_device")) }
  let(:report_content) { "" }
  let(:valid_mouse_report) { "\x01\x00\x00\x00\x00\x00\x01\x00\x00" } # Mock mouse report
  let(:valid_keyboard_report) { "\x7F\x00\x00\x00\x04\x00\x00\x00\x00" } # Mock keyboard report
  let(:unknown_report) { "\xFF" } # Unknown report ID

  describe "#parse" do
    before do
      # Set up the test file
      hidraw_device.hidraw_path.write(report_content)
      hidraw_device.hidraw_path.close
    end

    after do
      hidraw_device.hidraw_path.unlink
    end

    context "when a valid mouse report is given" do
      let(:report_content) { valid_mouse_report }

      it "should yield :begin mouse_state for a valid mouse report" do
        expect { |b| parser.parse(&b) }.to yield_with_args(:begin)
      end
    end

    context "when a valid keyboard report is given" do
      context "without a previous mouse state" do
        let(:report_content) {
          [
            valid_keyboard_report # Mouse state nil <- should keep previous state
          ].join
        }

        it "should yield :begin mouse_state for a valid keyboard report" do
          expect { |b| parser.parse(&b) }.to yield_with_args(nil)
        end
      end

      context "when previous mouse state is :update" do
        let(:report_content) {
          [
            valid_mouse_report,    # Mouse state :begin
            valid_mouse_report,    # Mouse state :update
            valid_keyboard_report # Mouse state :update <- should keep previous state
          ].join
        }

        it "should keep the previous mouse_state" do
          expect { |b| parser.parse(&b) }.to yield_successive_args(:begin, :update, :update)
        end
      end
    end

    it "should yield :end mouse_state when timeout occurs" do
      # read_with_timeout
      #   "" : treated as timeout when returning an empty string
      #   nil: exits the while loop when returning nil
      allow(parser).to receive(:read_with_timeout).with(any_args).and_return("", nil)
      expect { |b| parser.parse(&b) }.to yield_with_args(:end)
    end
  end

  describe "#parse_hid_report" do
    it "parses a valid mouse report" do
      expect(parser.parse_hid_report(valid_mouse_report)).to be :mouse
    end

    it "parses a valid keyboard report" do
      expect(parser.parse_hid_report(valid_keyboard_report)).to be :keyboard
    end

    it "handles unknown report IDs" do
      expect(Fusuma::MultiLogger).to receive(:warn).with(/Unknown Report ID: 255/)
      expect(parser.parse_hid_report(unknown_report)).to be nil
    end
  end

  describe "#translate_keycode" do
    it "translates valid keycodes" do
      expect(parser.translate_keycode(4)).to eq("a and A")
      expect(parser.translate_keycode(100)).to eq("0x64") # Hexadecimal
    end

    it "returns unknown code for unrecognized keycodes" do
      expect(parser.translate_keycode(200)).to eq("0xc8") # Hexadecimal
    end
  end
end
