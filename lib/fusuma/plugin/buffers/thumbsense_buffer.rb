# frozen_string_literal: true

module Fusuma
  module Plugin
    module Buffers
      # manage events and generate command
      class ThumbsenseBuffer < Buffer
        DEFAULT_SOURCE = "remap_touchpad_input"
        POINTING_STICK_SOURCE = "pointing_stick_input"

        def config_param_types
          {
            source: [String]
          }
        end

        # clear old events
        def clear_expired(*)
          return if @events.empty?

          # skip palm/begin record
          return if !ended?(@events.last)

          clear
        end

        # @param event [Event]
        # @return [NilClass, ThumbsenseBuffer]
        def buffer(event)
          case event.tag
          when source, POINTING_STICK_SOURCE
            @events.push(event)
            self
          end
        end

        # return [Integer]
        def finger
          @events.map { |e| e.record.finger }.max
        end

        def ended?(event)
          event.record.status == "end"
        end

        def begin?(event)
          event.record.status == "begin"
        end
      end
    end
  end
end
