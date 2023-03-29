# frozen_string_literal: true

require "fusuma/plugin/detectors/detector"

module Fusuma
  module Plugin
    module Detectors
      # Detect tap event
      class ThumbsenseDetector < Detector
        SOURCES = %w[thumbsense keypress].freeze
        BUFFER_TYPE = "thumbsense"
        GESTURE_RECORD_TYPE = "tap"

        def initialize
          super
          @continue_keycode = Set.new
        end

        # @param buffers [Array<Buffer>]
        # @return [Event] if event is detected
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          thumbsense_buffer = buffers.find { |b| b.type == BUFFER_TYPE }

          return if @continue_keycode.empty? && thumbsense_buffer.empty?

          return if @continue_keycode.empty? && palm_detected?(thumbsense_buffer)

          keypress_event = detect_keypress_event(buffers)
          thumbsense_event = thumbsense_buffer.events.last

          return if keypress_event.nil?

          # NOTE: begin/end index must be skippable for omitting press/release key on executor
          keypress_status = case keypress_event.record.status.to_sym
          when :pressed
            # no touch event, only pressing key
            return if thumbsense_event.nil?

            # touch event while pressing the key
            return if keypress_event.time < thumbsense_event.time

            # Even after touch is finished, keep thumbsense mode if you are pressing the key.
            # You can continue dragging even after lifting your finger from touchpad.
            @continue_keycode.add keypress_event.record.code

            return if touch_released?(thumbsense_buffer)

            :begin
          when :released
            if @continue_keycode.delete?(keypress_event.record.code)
              :end
            else
              return
            end
          else
            raise "unknown status: #{keypress_event.record.status}"
          end
          index = create_index(code: keypress_event.record.code, status: keypress_status)

          create_event(record: Events::Records::IndexRecord.new(index: index, trigger: :oneshot))
        end

        private

        def detect_keypress_event(buffers)
          keypress_buffer = buffers.find { |b| b.type == "keypress" }

          return if keypress_buffer.empty?

          keypress_buffer.events.last
        end

        # @param code [String]
        # @param status [String]
        # @return [Config::Index]
        def create_index(code:, status:)
          Config::Index.new(
            [
              Config::Index::Key.new("thumbsense"),
              Config::Index::Key.new(code),
              Config::Index::Key.new(status, skippable: true)
            ]
          )
        end

        # @return [TrueClass, FalseClass]
        def touch_released?(buffer)
          touch_num = buffer.events.count { |e| (e.record.status == "begin") }
          release_num = buffer.events.count { |e| e.record.status == "end" }

          touch_num <= release_num
        end

        def palm_detected?(buffer)
          buffer.events.any? { |e| (e.record.status == "palm") }
        end
      end
    end
  end
end
