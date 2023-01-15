# frozen_string_literal: true

require "fusuma/plugin/detectors/detector"

module Fusuma
  module Plugin
    module Detectors
      # Detect tap event
      class ThumbsenseDetector < Detector
        SOURCES = %w[tap keypress timer].freeze
        BUFFER_TYPE = "thumbsense"
        GESTURE_RECORD_TYPE = "tap"

        BASE_INTERVAL = 0.5
        BASE_TAP_TIME = 0.4

        # @param buffers [Array<Buffer>]
        # @return [Event] if event is detected
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          thumbsense_buffer = buffers.find { |b| b.type == BUFFER_TYPE }

          if thumbsense_buffer.empty?
            return
          end

          return if palm_detected?(thumbsense_buffer)

          return unless touching?(thumbsense_buffer)


          keypress_record = detect_keypress_record(buffers)

          return if keypress_record.nil?

          index = create_index(code: keypress_record.code, status: keypress_record.status)

          create_event(record: Events::Records::IndexRecord.new(index: index))
        end

        private

        def detect_keypress_record(buffers)
          keypress_buffer = buffers.find { |b| b.type == "keypress" }

          return if keypress_buffer.empty?

          keypress_buffer.events.last.record
        end

        # @param code [String]
        # @param status [String]
        # @return [Config::Index]
        def create_index(code:, status:)
          Config::Index.new(
            [
              Config::Index::Key.new("thumbsense"),
              Config::Index::Key.new(code),
              Config::Index::Key.new(status)
            ]
          )
        end

        # @return [TrueClass, FalseClass]
        def touching?(buffer)
          !released_all?(buffer)
        end

        # @return [TrueClass, FalseClass]
        def released_all?(buffer)
          touch_num = buffer.events.count { |e| (e.record.status == "begin") }
          release_num = buffer.events.count { |e| e.record.status == "end" }
          MultiLogger.debug(touch_num: touch_num, release_num: release_num)

          case buffer.finger
          when 1
            touch_num == release_num
          when 2
            touch_num == release_num + 1
          when 3
            touch_num == release_num + 1
          when 4
            touch_num > 0 && release_num > 0
          else
            false
          end
        end

        def palm_detected?(buffer)
          buffer.events.any? { |e| (e.record.status == "palm") }
        end
      end
    end
  end
end
