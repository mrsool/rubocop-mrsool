# frozen_string_literal: true

module RuboCop
  module Cop
    module Mrsool
      # Enforces that Sidekiq worker names match their file path and blocks unsafe renames.
      #
      # 1. The worker class name must match the name implied by the file path.
      # 2. Compares the current branch to the merge target (e.g. develop). If a worker file
      #    was added and another worker file in the same directory was deleted, that's a
      #    rename (e.g. sms_worker.rb -> notification_worker.rb). The deleted file(s) must
      #    be kept with an alias so enqueued jobs still work. Configure MergeTargetBranch
      #    or set CI env (e.g. GITHUB_BASE_REF). See:
      #    https://github.com/sidekiq/sidekiq/wiki/FAQ#how-do-i-safely-rename-a-job-class
      #
      # @example Allowed: class name matches path
      #   # app/workers/notification_worker.rb
      #   class NotificationWorker
      #     include Sidekiq::Worker
      #   end
      #
      # @example Allowed: safe rename - old file kept with alias
      #   # Keep app/workers/sms_worker.rb with: SmsWorker = NotificationWorker
      #
      # @example Disallowed: dirty rename - added notification_worker.rb, deleted sms_worker.rb
      #   # offense: keep sms_worker.rb (e.g. SmsWorker = NotificationWorker)
      #
      class SidekiqWorkerDirtyRename < Base
        MSG_NAME_MISMATCH = 'Do not change Sidekiq worker names. Expected `%<expected>s` (from path) but found `%<actual>s`. Keep the worker name the same.'
        MSG_DIRTY_RENAME = 'Sidekiq worker rename detected vs merge target: you added this file and deleted %<deleted_paths>s. Keep the deleted file(s) so both class names are loadable (e.g. OldWorker = NewWorker in the old file). See https://github.com/sidekiq/sidekiq/wiki/FAQ#how-do-i-safely-rename-a-job-class'

        WORKERS_PATH = %r{app/workers/}
        SIDEKIQ_WORKER = '(const (const nil? :Sidekiq) :Worker)'
        WORKER_SUFFIX = '_worker.rb'

        def_node_search :includes_sidekiq_worker?, "(send _ :include #{SIDEKIQ_WORKER})"

        def on_class(node)
          return unless in_workers_path?
          return unless includes_sidekiq_worker?(node)

          expected = expected_worker_name_from_path
          actual = full_class_name(node)
          if actual != expected
            add_offense(node, message: format(MSG_NAME_MISMATCH, expected: expected, actual: actual))
            return
          end

          check_safe_rename(node)
        end

        def on_module(node)
          # Only the innermost class is the worker; we check classes via on_class.
        end

        private

        def check_safe_rename(node)
          deleted_in_same_dir = deleted_worker_files_in_same_dir
          return if deleted_in_same_dir.empty?

          add_offense(
            node,
            message: format(MSG_DIRTY_RENAME, deleted_paths: deleted_in_same_dir.join(', '))
          )
        end

        # Returns relative paths of worker files that were deleted (vs merge target) in the
        # same directory as the current file. Empty if no merge target, git unavailable, or
        # current file wasn't added.
        def deleted_worker_files_in_same_dir
          diff = worker_diff_vs_merge_target
          return [] if diff.nil?

          current_relative = relative_path_from_root
          return [] unless diff[:added].include?(current_relative)

          current_dir = File.dirname(current_relative)
          diff[:deleted].select do |path|
            File.dirname(path) == current_dir && path.end_with?(WORKER_SUFFIX)
          end
        end

        def relative_path_from_root
          path = processed_source.file_path
          root = config.root_dir.to_s
          path.start_with?(root) ? path.sub("#{root}/", '').sub(%r{\A/}, '') : path
        end

        # Returns { added: [...], deleted: [...] } relative paths under app/workers/, or nil if unavailable.
        def worker_diff_vs_merge_target
          @worker_diff_vs_merge_target ||= compute_worker_diff_vs_merge_target
        end

        def compute_worker_diff_vs_merge_target
          ref = merge_target_ref
          return nil if ref.nil? || ref.empty?

          root = config.root_dir.to_s
          return nil unless File.directory?(File.join(root, '.git'))

          merge_base = nil
          Dir.chdir(root) do
            merge_base = `git merge-base HEAD #{ref} 2>/dev/null`.strip
            return nil if merge_base.empty?
          end

          added = []
          deleted = []
          Dir.chdir(root) do
            out = `git diff --name-status #{merge_base} HEAD -- app/workers/ 2>/dev/null`
            out.each_line do |line|
              line = line.strip
              next if line.empty?

              status = line[0]
              path = line[1..].strip
              path = path.split("\t").first if path.include?("\t")
              next unless path.end_with?(WORKER_SUFFIX)

              case status
              when 'A' then added << path
              when 'D' then deleted << path
              end
            end
          end
          { added: added, deleted: deleted }
        rescue StandardError
          @worker_diff_vs_merge_target = { added: [], deleted: [] }
        end

        def merge_target_ref
          cfg = cop_config['MergeTargetBranch']
          return cfg if cfg.is_a?(String) && !cfg.strip.empty?

          env_ref = ENV['GITHUB_BASE_REF'] || ENV['CI_MERGE_REQUEST_TARGET_BRANCH_NAME'] || ENV['TARGET_BRANCH']
          return nil if env_ref.nil? || env_ref.strip.empty?

          "origin/#{env_ref.strip}"
        end

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
