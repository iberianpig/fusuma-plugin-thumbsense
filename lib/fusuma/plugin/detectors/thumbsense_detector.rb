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
        # @return [Array<Event>] if Thumbsense context and Remap index when keypress is detected
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          @thumbsense_buffer ||= find_buffer(buffers, "thumbsense")
          @keypress_buffer ||= find_buffer(buffers, "keypress")

          layer_manager = Fusuma::Plugin::Remap::LayerManager.instance

          # layer is thumbsense => create thumbsense context and remap index
          # touch is touching   => create thumbsense context and remap index
          # touch is released   => remove thumbsense context
          # keypress -> touch   => remove thumbsense context
          if touch_released? && !thumbsense_layer?
            MultiLogger.debug("thumbsense layer removed")
            layer_manager.send_layer(layer: LAYER_CONTEXT, remove: true)
            return
          end

          # When keypress event is first:
          # If current layer is thumbsense, the layer should not be changed
          # If current layer is not thumbsense, it should remain a normal key
          # In other words, if the key event comes first, do nothing
          if keypress_first?
            MultiLogger.debug("keypress event is first")

            return
          end

          MultiLogger.debug("thumbsense context created") unless thumbsense_layer?
          layer_manager.send_layer(layer: LAYER_CONTEXT)

          # create thumbsense context
          context = create_event(
            record: Events::Records::ContextRecord.new(
              name: :thumbsense,
              value: true
            )
          )

          # TODO: Threshold
          # create remap index
          index = if (keys = pressed_codes) && !keys.empty?
            MultiLogger.debug("thumbsense remap index created: #{keys}")
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
        # @param type [String]
        # @return [Buffer]
        def find_buffer(buffers, type)
          buffers.find { |b| b.type == type }
        end

        # @return [Array<String>]
        def pressed_codes
          records = @keypress_buffer.events.map(&:record)
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
        def touching?
          !touch_released?(@thumbsense_buffer)
        end

        # @return [TrueClass, FalseClass]
        def touch_released?
          return true if @thumbsense_buffer.empty?

          @thumbsense_buffer.events.map(&:record).last&.status == "end"
        end

        # @return [TrueClass, FalseClass]
        def thumbsense_layer?
          return if @keypress_buffer.empty?

          last_keypress = @keypress_buffer.events.last.record
          return if last_keypress.status == "released"

          current_layer = last_keypress&.layer
          current_layer && current_layer["thumbsense"]
        end

        # Check if keypress event is first, before thumbsense event
        # If last keypress event is modifier key, return false
        # @param keypress_buffer [Buffer]
        # @param thumbsense_buffer [Buffer]
        # @return [TrueClass] if keypress event is first
        # @return [FalseClass] if keypress event is NOT first or buffers are empty
        def keypress_first?
          return false if @thumbsense_buffer.empty? || @keypress_buffer.empty?

          if (keys = pressed_codes) && !keys.empty?
            return false if MODIFIER_KEYS.include?(keys.first)
          end

          @keypress_buffer.events.first.time < @thumbsense_buffer.events.first.time
        end
      end
    end
  end
end
