# frozen_string_literal: true

module RuboCop
  module Cop
    module Mrsool
      class DoNotUseDeleteMatched < Base
        MSG = 'Do not use delete_matched, use RedisHashStore#delete_hash instead'

        def_node_matcher :delete_matched?, <<~PATTERN
          (send (send (...) :cache) :delete_matched (...))
        PATTERN

        def on_send(node)
          return unless delete_matched?(node)

          add_offense(node)
        end
      end
    end
  end
end
