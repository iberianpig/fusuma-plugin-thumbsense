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

          codes = detect_keypress(buffers)

          return unless codes

          index = create_index(codes: codes)

          create_event(record: Events::Records::IndexRecord.new(index: index))
        end

        private

        def detect_keypress(buffers)
          keypress_buffer = buffers.find { |b| b.type == "keypress" }

          return if keypress_buffer.empty?

          codes = pressed_codes(keypress_buffer.events.map(&:record))

          return if codes.empty?

          codes
        end

        def pressed_codes(records)
          codes = []
          records.each do |r|
            if r.status == "pressed"
              codes << r.code
            else
              codes.delete_if { |code| code == r.code }
            end
          end
          codes
        end

        # @return [Config::Index]
        def create_index(codes:)
          Config::Index.new(
            [
              Config::Index::Key.new("thumbsense"),
              Config::Index::Key.new(codes.join("+"))
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
