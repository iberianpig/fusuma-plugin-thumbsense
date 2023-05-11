# frozen_string_literal: true

# require 'fusuma/plugin/parsers/parser.rb'
# require 'fusuma/plugin/events/event.rb'

module Fusuma
  module Plugin
    module Parsers
      # parse libinput and generate event
      class ThumbsenseParser < Parser
        DEFAULT_SOURCE = "libinput_command_input"

        #    ... event7  - button state: touch 3 from BUTTON_STATE_AREA    event BUTTON_EVENT_UP          to BUTTON_STATE_NONE
        # 10766: event7  - button state: touch 1 from BUTTON_STATE_AREA    event BUTTON_EVENT_UP          to BUTTON_STATE_NONE
        # 10768: event7  - button state: touch 0 from BUTTON_STATE_AREA    event BUTTON_EVENT_UP          to BUTTON_STATE_NONE

        # @param record [String]
        # @return [Records::Gesture, nil]
        def parse_record(record)
          gesture = "touch"

          case record.to_s

          # touched
          when %r{\sevent\d+\s+-\sbutton state: touch (?<finger>[[:digit:]]) from BUTTON_STATE_NONE}
            status = "begin"
            finger = $~[:finger].to_i + 1
          # released
          when %r{\sevent\d+\s+-\sbutton state: touch (?<finger>[[:digit:]]) .* to BUTTON_STATE_NONE}
            status = "end"
            finger = $~[:finger].to_i + 1

          # palm
          when %r{\sevent\d+\s+-\spalm: touch (?<finger>[[:digit:]]) .*}
            status = "palm"
            finger = $~[:finger].to_i + 1
          else
            return
          end

          Events::Records::GestureRecord.new(status: status, gesture: gesture, finger: finger, delta: nil)
        end

        def tag
          "thumbsense_parser"
        end
      end
    end
  end
end
