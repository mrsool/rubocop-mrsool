# frozen_string_literal: true

module RuboCop
  module Cop
    module Mrsool
      class SystemTests < Base
        MSG_PATH = 'Prefer system tests over features. Move this file to spec/system/'
        MSG_TAG = 'Prefer system tests over features. Tag it with type: :system'

        def_node_matcher :type_tag?, <<~PATTERN
          (send
            _ :describe _
            (hash <$(pair ({sym | str} $_) ({sym | str} $_)) ...>))
        PATTERN

        def on_send(node)
          type_tag?(node) do |pair, key, val|
            if key.to_s == 'type' && val.to_s == 'feature'
              add_offense(pair, message: MSG_TAG)
            end
          end
        end

        def on_new_investigation
          file_path = processed_source.file_path

          return if config.file_to_exclude?(file_path) || !file_path.include?('/spec/features/')

          src = RuboCop::ProcessedSource.new(processed_source.buffer.source, RUBY_VERSION.to_f)
          describe_block = src.ast.to_a.detect { |node| node.type == :block } || src.ast
          add_offense(describe_block, message: MSG_PATH)
        end
      end
    end
  end
end

