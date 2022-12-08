# frozen_string_literal: true

module RuboCop
  module Cop
    module Mrsool
      class OrderBuyerId < Base
        extend AutoCorrector

        MSG = "Use `buyer?(user_or_id)`"

        # Matches `object.iBuyerId`
        BUYER_ID = "(send $(...) :iBuyerId)"

        # Matches `object.id` or any other expression.
        USER_ID = "{(send $_ :id) $_}"

        # Matches `==`, `!=` or `eql?`
        COMP_METHOD = "${:!= :== :eql?}"

        # Matches one of:
        #   `object.iBuyerId == expression`
        #   `object.iBuyerId != expression`
        #   `object.iBuyerId.eql?(expression)`
        def_node_matcher :left?, "(send #{BUYER_ID} #{COMP_METHOD} #{USER_ID})"

        # Matches one of:
        #   `expression == object.iBuyerId`
        #   `expression != object.iBuyerId`
        #   `expression.eql?(object.iBuyerId)`
        def_node_matcher :right?, "(send #{USER_ID} #{COMP_METHOD} #{BUYER_ID})"

        def on_send(node)
          left?(node) do |object, operator, compared_value|
            suggest(node, object, operator, compared_value)
          end

          right?(node) do |compared_value, operator, object|
            suggest(node, object, operator, compared_value)
          end
        end

        def suggest(node, object, operator, compared_value)
          add_offense(node) do |corrector|
            replacement = "#{object.source}.buyer?(#{compared_value.source})"
            replacement = "!#{replacement}" if operator.eql?(:!=)
            corrector.replace(node, replacement)
          end
        end
      end
    end
  end
end
