# frozen_string_literal: true

module RuboCop
  module Cop
    module Mrsool
      class AliasedAttributes < Base
        extend AutoCorrector

        def on_send(node)
          method_name = node.method_name.to_s.delete_suffix("=")

          aliases.each do |old_attr, new_attr|
            if method_name.to_sym.eql?(old_attr.to_sym)
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
