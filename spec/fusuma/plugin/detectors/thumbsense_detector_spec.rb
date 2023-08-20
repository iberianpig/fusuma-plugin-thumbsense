# frozen_string_literal: true

require "spec_helper"

require "fusuma/plugin/detectors/detector"
require "fusuma/plugin/buffers/buffer"
require "fusuma/plugin/events/event"

module Fusuma
  module Plugin
    module Detectors
      RSpec.describe ThumbsenseDetector do
        def thumbsense_generator(finger:, status:, time: Time.now)
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
        end

        def keypress_generator(code:, status:, time: Time.now)
          Events::Event.new(
            time: time,
            tag: "keypress_parser",
            record: Events::Records::KeypressRecord.new(
              code: code,
              status: status
            )
          )
        end

        before do
          @detector = ThumbsenseDetector.new
          @thumbsense_buffer = Buffers::ThumbsenseBuffer.new
          @keypress_buffer = Buffers::KeypressBuffer.new
          @buffers = [@thumbsense_buffer, @keypress_buffer]
        end

        describe "#detect" do
          context "with 1 finger thumbsense begin event in buffer" do
            before do
              [
                thumbsense_generator(finger: 1, status: "begin")
              ].each { |event| @thumbsense_buffer.buffer(event) }
            end

            context "without keypress" do
              before do
                @keypress_buffer.clear
              end

              it "detects thumbsense context and send layer" do
                expect(Fusuma::Plugin::Remap::LayerManager.instance).to receive(:send_layer).with(layer: ThumbsenseDetector::LAYER_CONTEXT)
                event = @detector.detect(@buffers)
                expect(event.record).to be_a Events::Records::ContextRecord
                expect(event.record.name).to eq :thumbsense
              end
            end

            context "when Modifier key is pressed" do
              before do
                [
                  keypress_generator(code: "LEFTSHIFT", status: "pressed")
                ].each { |event| @keypress_buffer.buffer(event) }
              end

              it "detects thumbsense context" do
                event = @detector.detect(@buffers)
                expect(event.record).to be_a Events::Records::ContextRecord
                expect(event.record.name).to eq :thumbsense
              end

              context "when non-Modifier key is pressed" do
                before do
                  [
                    keypress_generator(code: "A", status: "pressed")
                  ].each { |event| @keypress_buffer.buffer(event) }
                end

                it "does NOT detect thumbsense" do
                  expect(@detector.detect(@buffers)).to be_nil
                end
              end
            end
          end

          context "with 1 finger thumbsense begin/end events in buffer" do
            before do
              [
                thumbsense_generator(finger: 1, status: "begin"),
                thumbsense_generator(finger: 1, status: "end")
              ].each { |event| @thumbsense_buffer.buffer(event) }
            end

            it "does NOT detect thumbsense" do
              expect(@detector.detect(@buffers)).to be_nil
            end
          end

          context "with palm event in buffer" do
            before do
              [
                # When a `palm` event enters, `begin` also enters.
                # The order is not guaranteed, so `begin` may enter first.
                thumbsense_generator(finger: 1, status: "palm"),
                thumbsense_generator(finger: 1, status: "begin")
              ].shuffle { |event| @thumbsense_buffer.buffer(event) }
            end

            it "does NOT detect thumbsense" do
              expect(@detector.detect(@buffers)).to be_nil
            end

            context "with other finger thumbsense begin event in buffer" do
              before do
                [
                  thumbsense_generator(finger: 2, status: "begin")
                ].each { |event| @thumbsense_buffer.buffer(event) }
              end

              it "detect thumbsense" do
                event = @detector.detect(@buffers)
                expect(event.record).to be_a Events::Records::ContextRecord
                expect(event.record.name).to eq :thumbsense
              end
            end
          end

          context "with 2 fingers thumbsense events in buffer" do
            before do
              [
                thumbsense_generator(finger: 1, status: "begin"),
                thumbsense_generator(finger: 2, status: "begin")
              ].each { |event| @thumbsense_buffer.buffer(event) }
            end

            it "detects thumbsense context" do
              event = @detector.detect(@buffers)
              expect(event.record).to be_a Events::Records::ContextRecord
              expect(event.record.name).to eq :thumbsense
            end

            context "with second thumbsense end event in buffer" do
              before do
                [
                  thumbsense_generator(finger: 2, status: "end")
                ].each { |event| @thumbsense_buffer.buffer(event) }
              end

              it "detects thumbsense" do
                event = @detector.detect(@buffers)
                expect(event.record).to be_a Events::Records::ContextRecord
                expect(event.record.name).to eq :thumbsense
              end

              context "with other thumbsense palm event in buffer" do
                before do
                  [
                    thumbsense_generator(finger: 3, status: "palm")
                  ].each { |event| @thumbsense_buffer.buffer(event) }
                end

                it "detects thumbsense" do # because first thumbsense is still active
                  event = @detector.detect(@buffers)
                  expect(event.record).to be_a Events::Records::ContextRecord
                  expect(event.record.name).to eq :thumbsense
                end
              end
            end
          end

          context "with tap while pressing a key" do
            before do
              [
                keypress_generator(code: "J", status: "pressed")
              ].each { |event| @keypress_buffer.buffer(event) }
              [
                thumbsense_generator(finger: 1, status: "begin")
              ].each { |event| @thumbsense_buffer.buffer(event) }
            end

            it "does NOT detect thumbsense" do
              expect(@detector.detect(@buffers)).to be_nil
            end
          end

          context "with release tap while pressing a key" do
            before do
              @thumbsense_buffer.buffer(thumbsense_generator(finger: 1, status: "begin"))
              @keypress_buffer.buffer(keypress_generator(code: "J", status: "pressed"))
              @thumbsense_buffer.buffer(thumbsense_generator(finger: 1, status: "end"))
            end

            it "does NOT detect thumbsense" do
              expect(@detector.detect(@buffers)).to be_nil
            end
          end
        end
      end
    end
  end
end
