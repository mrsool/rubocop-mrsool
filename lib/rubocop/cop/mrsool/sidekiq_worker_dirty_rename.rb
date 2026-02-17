# frozen_string_literal: true

module RuboCop
  module Cop
    module Mrsool
      # Enforces that Sidekiq worker names are never changed.
      #
      # The worker name (the class name) must be the same as the name implied by
      # the file path. Developers are not allowed to rename Sidekiq workers or
      # their files—changing either breaks jobs already enqueued in Redis.
      #
      # @example Allowed: class name matches path (name unchanged)
      #   # app/workers/orders/expire_worker.rb
      #   module Orders
      #     class ExpireWorker
      #       include Sidekiq::Worker
      #     end
      #   end
      #
      # @example Disallowed: class or filename was changed
      #   # app/workers/orders/expire_worker.rb
      #   module Orders
      #     class ExpireOrderWorker  # offense: name must stay ExpireWorker
      #       include Sidekiq::Worker
      #     end
      #   end
      #
      class SidekiqWorkerDirtyRename < Base
        MSG = 'Do not change Sidekiq worker names. Expected `%<expected>s` (from path) but found `%<actual>s`. Keep the worker name the same.'

        WORKERS_PATH = %r{app/workers/}
        SIDEKIQ_WORKER = '(const (const nil? :Sidekiq) :Worker)'

        def_node_search :includes_sidekiq_worker?, "(send _ :include #{SIDEKIQ_WORKER})"

        def on_class(node)
          return unless in_workers_path?
          return unless includes_sidekiq_worker?(node)

          expected = expected_worker_name_from_path
          actual = full_class_name(node)
          return if actual == expected

          add_offense(node, message: format(MSG, expected: expected, actual: actual))
        end

        def on_module(node)
          # Only the innermost class is the worker; we check classes via on_class.
          # Modules don't need to be checked for name match by this cop.
        end

        private

        def in_workers_path?
          path = processed_source.file_path
          path.nil? ? false : path.include?('app/workers/')
        end

        def expected_worker_name_from_path
          path = processed_source.file_path
          relative = path.sub(/.*app\/workers\//, '').sub(/\.rb\z/, '')
          relative.split('/').map { |segment| camelize(segment) }.join('::')
        end

        def camelize(snake_string)
          snake_string.split('_').map(&:capitalize).join
        end

        def full_class_name(class_node)
          namespace = namespace_from_ancestors(class_node)
          short_name = const_name(class_node.identifier)
          namespace.empty? ? short_name : "#{namespace}::#{short_name}"
        end

        def namespace_from_ancestors(node)
          ancestors = []
          current = node.parent
          while current
            if current.module_type?
              name = current.identifier.children[1].to_s
              ancestors.unshift(name)
            elsif current.class_type? && current != node
              # Outer class: we want the full name of the outer class as prefix
              name = const_name(current.identifier)
              ancestors.unshift(name)
              break
            end
            current = current.parent
          end
          ancestors.join('::')
        end

        def const_name(node)
          case node.type
          when :const
            parent = node.children[0]
            name = node.children[1].to_s
            if parent.nil? || parent.type == :cbase
              name
            else
              "#{const_name(parent)}::#{name}"
            end
          when :cbase
            ''
          else
            node.source
          end
        end
      end
    end
  end
end
