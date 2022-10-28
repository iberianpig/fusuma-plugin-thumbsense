# frozen_string_literal: true

require "spec_helper"

require "fusuma/plugin/parsers/parser"
require "./lib/fusuma/plugin/parsers/thumbsense_parser"

module Fusuma
  module Plugin
    module Parsers
      RSpec.describe ThumbsenseParser do
        describe "#parse_record" do
          before do
            @parser = ThumbsenseParser.new
          end

          context "with 1 finger touch, then released" do
            before do
              lines_str = <<~LINES
                423979: event7  - button state: touch 0 from BUTTON_STATE_NONE    event BUTTON_EVENT_IN_AREA     to BUTTON_STATE_AREA
                  ... event7  - gesture state GESTURE_STATE_NONE → GESTURE_EVENT_FINGER_DETECTED → GESTURE_STATE_UNKNOWN
                423987: event7  - gesture state GESTURE_STATE_UNKNOWN → GESTURE_EVENT_HOLD_TIMEOUT → GESTURE_STATE_HOLD
                424068: event7  - gesture state GESTURE_STATE_HOLD → GESTURE_EVENT_HOLD_AND_MOTION → GESTURE_STATE_HOLD_AND_MOTION
                424083: event7  - button state: touch 0 from BUTTON_STATE_AREA    event BUTTON_EVENT_UP          to BUTTON_STATE_NONE
                  ... event7  - gesture state GESTURE_STATE_HOLD_AND_MOTION → GESTURE_EVENT_RESET → GESTURE_STATE_NONE
              LINES
              @records = lines_str.split("\n").map do |line|
                @parser.parse_record(line)
              end.compact
            end

            it "generate touch record" do
              expect(@records.map(&:gesture)).to all(eq "touch")
              expect(@records.map(&:finger)).to eq [1, 1]
              expect(@records.map(&:status)).to eq ["begin", "end"]
            end
          end

          context "with 1 finger touched in bottom area, then moved to state area and released" do
            before do
              lines_str = <<~LINES
                 ... event7  - button state: touch 0 from BUTTON_STATE_NONE    event BUTTON_EVENT_IN_BOTTOM_R to BUTTON_STATE_BOTTOM
                385: event7  - button state: touch 0 from BUTTON_STATE_BOTTOM  event BUTTON_EVENT_IN_AREA     to BUTTON_STATE_AREA
                512: event7  - button state: touch 0 from BUTTON_STATE_AREA    event BUTTON_EVENT_UP          to BUTTON_STATE_NONE
              LINES
              @records = lines_str.split("\n").map do |line|
                @parser.parse_record(line)
              end.compact
            end

            it "generate touch record" do
              expect(@records.map(&:gesture)).to all(eq "touch")
              expect(@records.map(&:finger)).to eq [1, 1]
              expect(@records.map(&:status)).to eq ["begin", "end"]
            end
          end

        end
      end
    end
  end
end
