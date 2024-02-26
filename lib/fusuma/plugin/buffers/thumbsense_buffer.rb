# frozen_string_literal: true

module Fusuma
  module Plugin
    module Buffers
      # manage events and generate command
      class ThumbsenseBuffer < Buffer
        DEFAULT_SOURCE = "remap_touchpad_input"

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
          return if event&.tag != source

          @events.push(event)
          self
        end

        # return [Integer]
        def finger
          @events.map { |e| e.record.finger }.max
        end

        def empty?
          @events.empty?
        end

        def present?
          !empty?
        end

        def select_by_events(&block)
          return enum_for(:select) unless block

          events = @events.select(&block)
          self.class.new events
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
