# frozen_string_literal: true

require "spec_helper"

require "fusuma/plugin/events/records/gesture_record"
require "fusuma/plugin/events/event"
require "fusuma/plugin/buffers/buffer"
require "fusuma/plugin/buffers/keypress_buffer"

module Fusuma
  module Plugin
    module Buffers
      RSpec.describe ThumbsenseBuffer do
        before do
          @buffer = ThumbsenseBuffer.new
          @event_generator = lambda { |time = nil, finger = 1, status = "begin"|
            Events::Event.new(time: time,
              tag: "thumbsense_parser",
              record: Events::Records::GestureRecord.new(
                status: status,
                gesture: "thumbsense",
                finger: finger,
                delta: nil
              ))
          }
        end

        describe "#type" do
          it { expect(@buffer.type).to eq "thumbsense" }
        end

        describe "#buffer" do
          it "buffers gesture event" do
            event = @event_generator.call(Time.now)
            @buffer.buffer(event)
            expect(@buffer.events).to eq [event]
          end

          it "does not buffer other event" do
            event = Events::Event.new(tag: "SHOULD NOT BUFFER", record: "dummy record")
            @buffer.buffer(event)
            expect(@buffer.events).to eq []
          end
        end

        describe "#clear_expired" do
          context "with including end" do
            it "does not clear any events" do
              time = Time.now
              event1 = @event_generator.call(time, 1, "begin")
              event2 = @event_generator.call(time + 0.1, 2, "begin")
              event3 = @event_generator.call(time + 0.2, 1, "end")
              event4 = @event_generator.call(time + 0.3, 2, "end")
              @buffer.buffer(event1)
              @buffer.clear_expired

              @buffer.buffer(event2)
              @buffer.clear_expired

              @buffer.buffer(event3)
              @buffer.clear_expired

              @buffer.buffer(event4)
              @buffer.clear_expired

              expect(@buffer.events).to eq []
            end
          end

          context "WITHOUT including end" do
            it "does not clear events" do
              time = Time.now
              event1 = @event_generator.call(time, 1, "begin")
              event2 = @event_generator.call(time + 0.1, 2, "begin")
              @buffer.buffer(event1)
              @buffer.clear_expired
              @buffer.buffer(event2)
              @buffer.clear_expired

              expect(@buffer.events).to eq [event1, event2]
            end
          end
        end

        describe "#empty?" do
          context "no gestures in buffer" do
            before { @buffer.clear }

            it { expect(@buffer.empty?).to be true }
          end

          context "buffered some gestures" do
            before { @buffer.buffer(@event_generator.call(Time.now, "begin")) }

            it { expect(@buffer.empty?).to be false }
          end
        end
      end
    end
  end
end
