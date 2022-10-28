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
          (record.to_s =~ %r{\sevent\d+\s+-\sbutton state: touch (?<finger>[[:digit:]])})
        end
      end
    end
  end
end
