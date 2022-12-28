# frozen_string_literal: true

require "fusuma/device"

module Fusuma
  module Plugin
    module Filters
      # Filter keyboard events from libinput_command_input
      class ThumbsenseFilter < Filter
        DEFAULT_SOURCE = "libinput_command_input"

        # @return [TrueClass] when keeping it
        # @return [FalseClass] when discarding it
        def keep?(record)
          case record.to_s
          when %r{\sevent\d+\s+-\sbutton state: touch (?<finger>[[:digit:]])}
            true
          when %r{\sevent\d+\s+-\spalm: touch (?<finger>[[:digit:]])}
            true
          else
            false
          end
        end
      end
    end
  end
end
