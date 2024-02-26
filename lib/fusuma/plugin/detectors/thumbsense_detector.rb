# frozen_string_literal: true

require "fusuma/plugin/detectors/detector"
require "fusuma/plugin/remap/layer_manager"

require "set"

module Fusuma
  module Plugin
    module Detectors
      # Detect Thumbsense context and change remap layer of fusuma-plugin-remap
      class ThumbsenseDetector < Detector
        # keypress buffer is used to detect modifier keys
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
        # @param buffers [Array<Buffer>] ThumbsenseBuffer, KeypressBuffer
        # @return [Event] if Thumbsense context is detected
        # @return [Array<Event>] if Thumbsense context and Remap index are detected(when modifier keys are pressed)
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          thumbsense_buffer = find_thumbsense_buffer(buffers)
          keypress_buffer = find_keypress_buffer(buffers)

          layer_manager = Fusuma::Plugin::Remap::LayerManager.instance

          MultiLogger.debug("thumbsense_buffer: #{thumbsense_buffer.events.map(&:record).map { |r| "#{r.finger} #{r.gesture} #{r.status}" }}")

          # layer is thumbsense => create thumbsense context and remap index
          # touch is touching   => create thumbsense context and remap index
          # touch is released   => remove thumbsense context
          # keypress -> touch   => remove thumbsense context
          if (touch_released?(thumbsense_buffer) && !thumbsense_layer?(keypress_buffer)) || keypress_first?(keypress_buffer, thumbsense_buffer)
            layer_manager.send_layer(layer: LAYER_CONTEXT, remove: true)
            return
          end

          layer_manager.send_layer(layer: LAYER_CONTEXT)

          # create thumbsense context
          context = create_event(
            record: Events::Records::ContextRecord.new(
              name: :thumbsense,
              value: true
            )
          )

          # create remap index if modifier keys are pressed
          index = if (keys = pressed_codes(keypress_buffer)) && !keys.empty?
            MultiLogger.debug("thumbsense context and remap index created: #{keys}")
            combined_keys = keys.join("+")
            create_event(
              record: Events::Records::IndexRecord.new(
                index: Config::Index.new([:remap, combined_keys])
              )
            )
          end

          [context, index].compact
        end

        private

        # @param buffers [Array<Buffer>]
        def find_thumbsense_buffer(buffers)
          buffers.find { |b| b.type == BUFFER_TYPE }
        end

        # @param buffers [Array<Buffer>]
        def find_keypress_buffer(buffers)
          buffers.find { |b| b.type == "keypress" }
        end

        # @return [Array<String>]
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

        # @return [TrueClass, FalseClass]
        def touching?(thumbsense_buffer)
          !touch_released?(thumbsense_buffer)
        end

        # @return [TrueClass, FalseClass]
        def touch_released?(thumbsense_buffer)
          return true if thumbsense_buffer.empty?

          thumbsense_buffer.events.map(&:record).last&.status == "end"
        end

        # @return [TrueClass, FalseClass]
        def thumbsense_layer?(keypress_buffer)
          return if keypress_buffer.empty?

          current_layer = keypress_buffer.events.last.record&.layer
          current_layer && current_layer["thumbsense"]
        end

        # @return [TrueClass, FalseClass]
        def keypress_first?(keypress_buffer, thumbsense_buffer)
          return false if thumbsense_buffer.empty?
          return false if keypress_buffer.empty?

          keypress_buffer.events.last.time < thumbsense_buffer.events.last.time
        end
      end
    end
  end
end
