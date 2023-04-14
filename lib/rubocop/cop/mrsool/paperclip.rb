# frozen_string_literal: true

module RuboCop
  module Cop
    module Mrsool
      class Paperclip < Base
        MSG = 'Paperclip is deprecated in favour of ActiveStorage: https://thoughtbot.com/blog/closing-the-trombone'

        def_node_matcher :paperclip_def?, <<-PATTERN
        (send nil? :has_attached_file ...)
        PATTERN

        def on_send(node)
          return unless paperclip_def?(node)

          add_offense(node)
        end
      end
    end
  end
end
