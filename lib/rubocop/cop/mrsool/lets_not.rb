# frozen_string_literal: true

module RuboCop
  module Cop
    module Mrsool
      class LetsNot < Base
        MSG = 'Do not use `let` for test setup. https://thoughtbot.com/blog/lets-not'

        def_node_matcher :let_def?, <<-PATTERN
          {
            (block $(send nil? :let {(sym $_) (str $_)}) ...)
            $(send nil? :let {(sym $_) (str $_)} block_pass)
          }
        PATTERN

        def on_block(node)
          return unless let_def?(node)

          add_offense(node)
        end
      end
    end
  end
end
