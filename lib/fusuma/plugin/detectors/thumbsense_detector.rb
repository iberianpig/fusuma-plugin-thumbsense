# frozen_string_literal: true

require "fusuma/plugin/detectors/detector"

require "fusuma/plugin/remap/layer_manager"

module Fusuma
  module Plugin
    module Detectors
      # Detect Thumbsense context and change remap layer of fusuma-plugin-remap
      class ThumbsenseDetector < Detector
        SOURCES = %w[thumbsense gesture keypress].freeze
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

        # @param buffers [Array<Buffer>]
        # @return [Event] if event is detected
        # @return [NilClass] if event is NOT detected
        def detect(buffers)
          thumbsense_buffer = buffers.find { |b| b.type == BUFFER_TYPE }

          return if thumbsense_buffer.empty?

          MultiLogger.debug("thumbsense_buffer: #{thumbsense_buffer.events.map(&:record).map { |r| "#{r.finger} #{r.gesture} #{r.status}" }}")

          layer_manager = Fusuma::Plugin::Remap::LayerManager.instance
          layer = {thumbsense: true}

          if touch_released?(thumbsense_buffer)
            layer_manager.send_layer(layer: layer, remove: true)
            return
          end

          keypress_buffer = buffers.find { |b| b.type == "keypress" }
          if pressed_codes(keypress_buffer).all? { |code| MODIFIER_KEYS.include?(code) }

            # Even if the palm is detected, keep the thumbsense layer until `:end` event
            if palm_detected?(thumbsense_buffer)
              hold_events = fetch_hold_events(buffers)
              MultiLogger.debug "hold_events: #{hold_events.map(&:record).map { |r| "#{r.finger} #{r.gesture} #{r.status}" }}"
              if hold_events.empty? || hold_events.last.record.status != "begin"
                layer_manager.send_layer(layer: layer, remove: true)
                return
              end
            end

            layer_manager.send_layer(layer: layer)
            record = Events::Records::ContextRecord.new(
              name: "thumbsense",
              value: true
            )
            return create_event(record: record)
          end
          nil
        end

        # Change remap layer of fusuma-plugin-remap
        # @param context [Hash]
        def add_layer
          Fusuma::Plugin::Remap::Layer.add({thumbsense: true})
        end

        # Remove remap layer of fusuma-plugin-remap
        # @param context [Hash]
        def remove_layer
          Fusuma::Plugin::Remap::Layer.remove({thumbsense: true})
        end

        private

        def fetch_hold_events(buffers)
          buffers.find { |b| b.type == "gesture" }
            .select_from_last_begin
            .select_by_events { |e| e.record.gesture == "hold" }.events
        end

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

        def palm_detected?(thumbsense_buffer)
          thumbsense_buffer.events.any? { |e| (e.record.status == "palm") }
        end

        def palm_count(thumbsense_buffer)
          thumbsense_buffer.events.count { |e| (e.record.status == "palm") }
        end

        def thumbsense_keys
        end
      end
    end
  end
end
