# frozen_string_literal: true

module RuboCop
  module Cop
    module Mrsool
      class RolloutContainer < Base
        extend AutoCorrector

        MSG = 'Use `Rollout[:platform]` or consider moving the flag to a feature specific container like `Rollout[:your_feature]`'

        def_node_matcher :old_definition?, '(send $(const nil? :ROLLOUT_FLAGS) $_)'

        def on_send(node)
          old_definition?(node) do |container, flag|
            # require 'pry'; binding.pry
            add_offense(container) do |corrector|
              replacement = "Rollout[:platform].#{flag}"
              corrector.replace(node, replacement)
            end
          end
        end
      end
    end
  end
end
