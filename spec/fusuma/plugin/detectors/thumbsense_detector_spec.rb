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
            tag: "remap_touchpad_input",
            record: Events::Records::GestureRecord.new(
              finger: finger,
              gesture: "thumbsense",
              status: status,
              delta: Events::Records::GestureRecord::Delta.new(0, 0, 0, 0)
            )
          )
        end

        def keypress_generator(code:, status:, layer: nil, time: Time.now)
          Events::Event.new(
            time: time,
            # NOTE: "remap_keyboard_input" is the original key event obtained from fusuma-plugin-remap
            # The source of the event received by the keypress_buffer is usually "keypress_parser" tag,
            # but if fusuma-plugin-remap is installed as a dependency, it will be "remap_keyboard_input" with plugin_default.
            tag: "remap_keyboard_input",
            record: Events::Records::KeypressRecord.new(code: code, status: status, layer: layer)
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

                context_event, index_event = @detector.detect(@buffers)

                expect(context_event.record).to be_a Events::Records::ContextRecord
                expect(context_event.record.name).to eq :thumbsense

                expect(index_event).to be_nil
              end
            end

            context "when Modifier key is pressed" do
              before do
                [
                  keypress_generator(code: "LEFTSHIFT", status: "pressed", layer: {thumbsense: true})
                ].each { |event| @keypress_buffer.buffer(event) }
              end

              it "detects thumbsense context" do
                expect(Fusuma::Plugin::Remap::LayerManager.instance).to receive(:send_layer).with(layer: ThumbsenseDetector::LAYER_CONTEXT)

                context_event, index_event = @detector.detect(@buffers)

                expect(context_event.record).to be_a Events::Records::ContextRecord
                expect(context_event.record.name).to eq :thumbsense

                expect(index_event.record).to be_a Events::Records::IndexRecord
                expect(index_event.record.index).to eq Config::Index.new([:remap, "LEFTSHIFT"])
              end
            end

            context "when non-Modifier key is pressed" do
              before do
                [
                  keypress_generator(code: "A", status: "pressed")
                ].each { |event| @keypress_buffer.buffer(event) }
              end

              it "does detect thumbsense" do
                expect(Fusuma::Plugin::Remap::LayerManager.instance).to receive(:send_layer).with(layer: ThumbsenseDetector::LAYER_CONTEXT)

                context_event, index_event = @detector.detect(@buffers)

                expect(context_event.record).to be_a Events::Records::ContextRecord
                expect(context_event.record.name).to eq :thumbsense

                expect(index_event.record).to be_a Events::Records::IndexRecord
                expect(index_event.record.index).to eq Config::Index.new([:remap, "A"])
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
              expect(Fusuma::Plugin::Remap::LayerManager.instance).to receive(:send_layer).with(
                layer: ThumbsenseDetector::LAYER_CONTEXT,
                remove: true
              )
              expect(@detector.detect(@buffers)).to be_nil
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
              @keypress_buffer.buffer(keypress_generator(code: "J", status: "pressed", layer: {thumbsense: true}))
              @thumbsense_buffer.buffer(thumbsense_generator(finger: 1, status: "end"))
            end

            it "does NOT detect thumbsense" do
              expect(@detector.detect(@buffers)).to be_nil
            end
          end

          context "with tap after pressing a modifier key" do
            before do
              @keypress_buffer.buffer(keypress_generator(code: "LEFTSHIFT", status: "pressed"))
              @thumbsense_buffer.buffer(thumbsense_generator(finger: 1, status: "begin"))
            end

            it "detects thumbsense" do
              expect(Fusuma::Plugin::Remap::LayerManager.instance).to receive(:send_layer).with(layer: ThumbsenseDetector::LAYER_CONTEXT)

              context_event, index_event = @detector.detect(@buffers)

              expect(context_event.record).to be_a Events::Records::ContextRecord
              expect(context_event.record.name).to eq :thumbsense

              expect(index_event.record).to be_a Events::Records::IndexRecord
              expect(index_event.record.index).to eq Config::Index.new([:remap, "LEFTSHIFT"])
            end

            context "with add J key" do
              before do
                @keypress_buffer.buffer(keypress_generator(code: "J", status: "pressed", layer: {thumbsense: true}))
              end

              it "detects thumbsense" do
                expect(Fusuma::Plugin::Remap::LayerManager.instance).to receive(:send_layer).with(layer: ThumbsenseDetector::LAYER_CONTEXT)

                context_event, index_event = @detector.detect(@buffers)

                expect(context_event.record).to be_a Events::Records::ContextRecord
                expect(context_event.record.name).to eq :thumbsense

                expect(index_event.record).to be_a Events::Records::IndexRecord
                expect(index_event.record.index).to eq Config::Index.new([:remap, "LEFTSHIFT+J"])
              end
            end
          end

          context "with tap after pressing a non-modifier key" do
            before do
              @keypress_buffer.buffer(keypress_generator(code: "A", status: "pressed"))
              @thumbsense_buffer.buffer(thumbsense_generator(finger: 1, status: "begin"))
            end

            it "does NOT detect thumbsense" do
              expect(Fusuma::Plugin::Remap::LayerManager.instance).not_to receive(:send_layer).with(layer: ThumbsenseDetector::LAYER_CONTEXT)

              context_event, index_event = @detector.detect(@buffers)

              expect(context_event).to be_nil
              expect(index_event).to be_nil
            end

            context "with add J key" do
              before do
                @keypress_buffer.buffer(keypress_generator(code: "J", status: "pressed", layer: {thumbsense: false}))
              end

              it "does NOT detect thumbsense" do
                expect(Fusuma::Plugin::Remap::LayerManager.instance).not_to receive(:send_layer).with(layer: ThumbsenseDetector::LAYER_CONTEXT)

                context_event, index_event = @detector.detect(@buffers)

                expect(context_event).to be_nil
                expect(index_event).to be_nil
              end
            end
          end
        end
      end
    end
  end
end
