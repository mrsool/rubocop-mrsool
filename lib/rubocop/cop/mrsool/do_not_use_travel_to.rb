# frozen_string_literal: true

module RuboCop
  module Cop
    module Mrsool
      class DoNotUseTravelTo < Base
        MSG = 'Do not use travel_to, use Timecop.freeze instead. Check our freeze meta syntax in rails_helper.rb'

        def_node_matcher :travel_to_def?, <<~PATTERN
          (send nil? :travel_to _)
        PATTERN

        def on_send(node)
          return unless travel_to_def?(node)

          add_offense(node, message: MSG)
        end
      end
    end
  end
end
