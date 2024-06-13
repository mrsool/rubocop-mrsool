# frozen_string_literal: true

module RuboCop
  module Cop
    module Mrsool
      class AliasedAttributes < Base
        extend AutoCorrector

        def on_send(node)
          aliases.each do |old_attr, new_attr|
            if node.method_name == old_attr.to_sym
              add_offense(node, message: "Use `#{new_attr}` instead of `#{old_attr}`") do |corrector|
                corrector.replace(node.loc.selector, new_attr)
              end
            end
          end
        end

        private

        def aliases
          cop_config["Aliases"] || {}
        end
      end
    end
  end
end
