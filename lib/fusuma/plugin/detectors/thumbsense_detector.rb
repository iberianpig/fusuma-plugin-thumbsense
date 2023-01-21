# frozen_string_literal: true

require "fusuma/plugin/detectors/detector"

module Fusuma
  module Plugin
    module Detectors
      # Detect tap event
      class ThumbsenseDetector < Detector
        SOURCES = %w[tap keypress].freeze
        BUFFER_TYPE = "thumbsense"
        GESTURE_RECORD_TYPE = "tap"

        # @param buffers [Array<Buffer>]
        # @return [Event] if event is detected
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          thumbsense_buffer = buffers.find { |b| b.type == BUFFER_TYPE }

          return if thumbsense_buffer.empty?

          return if palm_detected?(thumbsense_buffer)

          return unless touching?(thumbsense_buffer)

          keypress_record = detect_keypress_record(buffers)

          return if keypress_record.nil?

          # NOTE: set skippable begin/end index for omitting press/release key on executor
          status = case keypress_record.status.to_sym
          when :pressed
            :begin
          when :released
            :end
          else
            raise "unknown status: #{keypress_record.status}"
          end
          index = create_index(code: keypress_record.code, status: status)

          # NOTE: Pressing the key has both a start and an end,
          # but since it is not a rapid press, it should be treated as a one-shot.
          create_event(record: Events::Records::IndexRecord.new(index: index, trigger: :oneshot))
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
              Config::Index::Key.new(status, skippable: true)
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
