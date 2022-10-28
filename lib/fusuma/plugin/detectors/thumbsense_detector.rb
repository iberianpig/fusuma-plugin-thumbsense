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

          if thumbsense_buffer.empty? # || moved?(thumbsense_buffer: thumbsense_buffer, gesture_buffer: gesture_buffer)
            return
          end

          return unless touching?(thumbsense_buffer)

          codes = detect_keypress(buffers)

          return unless codes

          index = create_index(codes: codes)

          create_event(record: Events::Records::IndexRecord.new(index: index))
        end

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
        def moved?(thumbsense_buffer:, gesture_buffer:)
          thumbsense_buffer.events.any? { |e| e.record.status == "move" } ||
            # FIXME: Find good parameter for ignoring
            gesture_buffer.events.count { |e| thumbsense_buffer.events.first.time < e.time } > 5
        end

        # @return [TrueClass, FalseClass]
        def released_all?(buffer)
          touch_num = buffer.events.count { |e| (e.record.status == "begin") }
          release_num = buffer.events.count { |e| e.record.status == "end" }
          MultiLogger.info(touch_num: touch_num, release_num: release_num)

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

        def calc_holding_time(thumbsense_buffer:, timer_buffer:)
          last_time = if timer_buffer && !timer_buffer.empty? &&
              (thumbsense_buffer.events.last.time < timer_buffer.events.last.time)
            timer_buffer.events.last.time
          else
            thumbsense_buffer.events.last.time
          end
          last_time - thumbsense_buffer.events.first.time
        end

        private

        def enough?(index:, direction:)
          enough_interval?(index: index, direction: direction)
        end

        def enough_interval?(index:, direction:)
          return true if first_time?
          return true if (Time.now - @last_time) > interval_time(index: index, direction: direction)

          false
        end

        def interval_time(index:, direction:)
          @interval_time ||= {}
          @interval_time[index.cache_key] ||= begin
            keys_specific = Config::Index.new [*index.keys, "interval"]
            keys_global = Config::Index.new ["interval", direction]
            config_value = Config.search(keys_specific) ||
              Config.search(keys_global) || 1
            BASE_INTERVAL * config_value
          end
        end
      end

      # class Keypress
      #   SOURCES = %w[keypress].freeze
      #
      #   # @param buffers [Array<Event>]
      #   # @return [Array<String>] if pressing keys are detected
      #   # @return [NilClass] if pressing keys are NOT detected
      #   def detect_codes(buffers)
      #     keypress_buffer = find_buffer(buffers)
      #
      #     return if keypress_buffer.empty?
      #     require 'debug'; debugger
      #
      #     codes = pressed_codes(keypress_buffer.events.map(&:record))
      #
      #     return if codes.empty?
      #
      #     codes
      #   end
      #
      #   private
      #
      #   def find_buffer(buffers)
      #     buffers.find { |b| b.type == "keypress" }
      #   end
      #
      #   def pressed_codes(records)
      #     codes = []
      #     records.each do |r|
      #       if r.status == "pressed"
      #         codes << r.code
      #       else
      #         codes.delete_if { |code| code == r.code }
      #       end
      #     end
      #     codes
      #   end
      # end
    end
  end
end
