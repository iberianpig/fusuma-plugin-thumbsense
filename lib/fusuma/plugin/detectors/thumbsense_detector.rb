# frozen_string_literal: true

require "fusuma/plugin/detectors/detector"
require "fusuma/plugin/remap/layer_manager"

require "set"

module Fusuma
  module Plugin
    module Detectors
      # Detect Thumbsense context and change remap layer of fusuma-plugin-remap
      class ThumbsenseDetector < Detector
        SOURCES = %w[thumbsense keypress].freeze
        BUFFER_TYPE = "thumbsense"

        MODIFIER_KEYS = Set.new(%w[
          CAPSLOCK
          LEFTALT
          LEFTCTRL
          LEFTMETA
          LEFTSHIFT
          RIGHTALT
          RIGHTCTRL
          RIGHTSHIFT
          RIGHTMETA
        ])

        LAYER_CONTEXT = {thumbsense: true}.freeze

        # Detect Context event and change remap layer of fusuma-plugin-remap
        # @param buffers [Array<Buffer>]
        # @return [Event] if Thumbsense context is detected
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          thumbsense_buffer = buffers.find { |b| b.type == BUFFER_TYPE }

          return if thumbsense_buffer.empty?

          MultiLogger.debug("thumbsense_buffer: #{thumbsense_buffer.events.map(&:record).map { |r| "#{r.finger} #{r.gesture} #{r.status}" }}")

          layer_manager = Fusuma::Plugin::Remap::LayerManager.instance

          if touch_released?(thumbsense_buffer)
            layer_manager.send_layer(layer: LAYER_CONTEXT, remove: true)
            return
          end

          keypress_buffer = buffers.find { |b| b.type == "keypress" }

          # If only modifier keys are pressed or no key is pressed
          if pressed_codes(keypress_buffer).all? { |code| MODIFIER_KEYS.include?(code) }

            # Even if the palm is detected, keep the thumbsense layer until `:end` event
            if palm_detected?(thumbsense_buffer)
              layer_manager.send_layer(layer: LAYER_CONTEXT, remove: true)
              return
            end

            layer_manager.send_layer(layer: LAYER_CONTEXT)

            # create thumbsense context
            record = Events::Records::ContextRecord.new(
              name: :thumbsense,
              value: true
            )
            return create_event(record: record)
          end

          nil
        end

        private

        def pressed_codes(keypress_buffer)
          records = keypress_buffer.events.map(&:record)
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

        def touching?(thumbsense_buffer)
          !touch_released?(thumbsense_buffer)
        end

        # @return [TrueClass, FalseClass]
        def touch_released?(thumbsense_buffer)
          thumbsense_events = thumbsense_buffer.events
          touch_num = thumbsense_events.count { |e| (e.record.status == "begin") }
          release_num = thumbsense_events.count { |e| e.record.status == "end" }

          touch_num <= release_num
        end

        # Detect palm, except when there is another touch
        # @param thumbsense_buffer [Buffer]
        # @return [TrueClass, FalseClass]
        def palm_detected?(thumbsense_buffer)
          # finger is a number to distinguish different touches and palms
          # If the count remains, it is judged as a touch state
          touch_state_per_finger = {}
          thumbsense_buffer.events.each do |e|
            f = e.record.finger
            touch_state_per_finger[f] ||= 0

            case e.record.status
            when "begin"
              touch_state_per_finger[f] += 1
            when "palm"
              if touch_state_per_finger[f] < 0
                # NOTE: If Palm continues, it is equivalent to end
                touch_state_per_finger[f] = 0
              else
                touch_state_per_finger[f] -= 1
              end
            when "end"
              touch_state_per_finger[f] = 0
            end
          end
          touch_state_per_finger.values.all?(&:zero?)
        end
      end
    end
  end
end
