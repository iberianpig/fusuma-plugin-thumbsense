# frozen_string_literal: true

require "spec_helper"

require "fusuma/plugin/detectors/detector"
require "fusuma/plugin/buffers/gesture_buffer"
require "fusuma/plugin/events/event"

module Fusuma
  module Plugin
    module Detectors
      RSpec.describe ThumbsenseDetector do
        before do
          @detector = ThumbsenseDetector.new
          @thumbsense_buffer = Buffers::ThumbsenseBuffer.new
          @keypress_buffer = Buffers::KeypressBuffer.new
          @buffers = [@thumbsense_buffer, @keypress_buffer]

          @thumbsense_event_generator = lambda { |time, finger, status|
            Events::Event.new(
              time: time,
              tag: "thumbsense_parser",
              record: Events::Records::GestureRecord.new(
                finger: finger,
                gesture: "thumbsense",
                status: status,
                delta: Events::Records::GestureRecord::Delta.new(0, 0, 0, 0)
              )
            )
          }
          @keypress_event_generator = lambda { |time, code, status|
            Events::Event.new(
              time: time,
              tag: "keypress_parser",
              record: Events::Records::KeypressRecord.new(
                code: code,
                status: status
              )
            )
          }
        end

        describe "#detect" do
          context "with 1 finger thumbsense begin event in buffer" do
            before do
              [
                @thumbsense_event_generator.call(Time.now, 1, "begin")
              ].each { |event| @thumbsense_buffer.buffer(event) }
            end

            context "without keypress" do
              before do
                @keypress_buffer.clear
              end

              it "does NOT detect thumbsense" do
                expect(@detector.detect(@buffers)).to be_nil
              end
            end

            context "when J key is pressed" do
              before do
                [
                  @keypress_event_generator.call(Time.now, "J", "pressed")
                ].each { |event| @keypress_buffer.buffer(event) }
              end

              it "generates thumbsense pressed" do
                event = @detector.detect(@buffers)
                expect(event.record).to be_a Events::Records::IndexRecord
                key_symbol = event.record.index.keys.map(&:symbol)
                expect(key_symbol).to eq [:thumbsense, :J, :pressed]
              end
            end

            context "when J key is pressed and released" do
              before do
                [
                  @keypress_event_generator.call(Time.now, "J", "pressed"),
                  @keypress_event_generator.call(Time.now, "J", "released")
                ].each { |event| @keypress_buffer.buffer(event) }
              end

              it "generates thumbsense released" do
                event = @detector.detect(@buffers)
                expect(event.record).to be_a Events::Records::IndexRecord
                key_symbol = event.record.index.keys.map(&:symbol)
                expect(key_symbol).to eq [:thumbsense, :J, :released]
              end
            end
          end

          context "with 1 finger thumbsense begin/end events in buffer" do
            before do
              [
                @thumbsense_event_generator.call(Time.now, 1, "begin"),
                @thumbsense_event_generator.call(Time.now, 1, "end")
              ].each { |event| @thumbsense_buffer.buffer(event) }
            end
            context "with keypress" do
              before do
                [
                  @keypress_event_generator.call(Time.now, "J", "pressed")
                ].each { |event| @keypress_buffer.buffer(event) }
              end

              it "does NOT detect thumbsense" do
                expect(@detector.detect(@buffers)).to be_nil
              end
            end
          end

          context "with palm event in buffer" do
            before do
              [
                @thumbsense_event_generator.call(Time.now, 1, "palm")
              ].each { |event| @thumbsense_buffer.buffer(event) }
            end

            it "does NOT detect thumbsense" do
              expect(@detector.detect(@buffers)).to be_nil
            end

            context "when J key is pressed" do
              before do
                [
                  @keypress_event_generator.call(Time.now, "J", "pressed")
                ].each { |event| @keypress_buffer.buffer(event) }
              end

              it "does NOT detect thumbsense" do
                expect(@detector.detect(@buffers)).to be_nil
              end
            end
          end

          context "with 2 fingers thumbsense events in buffer" do
            before do
              [
                @thumbsense_event_generator.call(Time.now, 1, "begin"),
                @thumbsense_event_generator.call(Time.now, 2, "begin")
              ].each { |event| @thumbsense_buffer.buffer(event) }
            end
            context "with keypress" do
              before do
                [
                  @keypress_event_generator.call(Time.now, "J", "pressed")
                ].each { |event| @keypress_buffer.buffer(event) }
              end

              it "generates thumbsense pressed" do
                key_symbol = @detector.detect(@buffers).record.index.keys.map(&:symbol)
                expect(key_symbol).to eq [:thumbsense, :J, :pressed]
              end
            end
          end
        end
      end
    end
  end
end
