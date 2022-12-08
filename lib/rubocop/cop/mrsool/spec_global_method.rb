# frozen_string_literal: true

module RuboCop
  module Cop
    module Mrsool
      class SpecGlobalMethod < Base
        MSG = "Avoid global methods. Move it inside `RSpec.describe` to prevent random test failures."

        def on_def(node)
          parent = node.parent
          add_offense(node) if parent.type.eql?(:begin) && parent.parent.nil?
        end
      end
    end
  end
end
