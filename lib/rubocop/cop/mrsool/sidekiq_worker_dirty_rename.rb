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

          # Exclude paths that exist on disk with the correct alias (OldWorker = NewWorker)
          new_worker_name = expected_worker_name_from_path
          still_dirty = deleted_in_same_dir.reject do |rel_path|
            full_path = File.join(root_dir, rel_path)
            next false unless File.file?(full_path)

            old_worker_name = worker_name_from_relative_path(rel_path)
            file_contains_correct_alias?(full_path, old_worker_name, new_worker_name)
          end
          return if still_dirty.empty?

          add_offense(
            node,
            message: format(MSG_DIRTY_RENAME, deleted_paths: still_dirty.join(', '))
          )
        end

        # Expected worker class name from a relative path (e.g. app/workers/sms_worker.rb -> SmsWorker)
        def worker_name_from_relative_path(rel_path)
          base = rel_path.sub(%r{\A.*app/workers/}, '').sub(/\.rb\z/, '')
          base.split('/').map { |s| camelize(s) }.join('::')
        end

        # True if the file contains a constant assignment: old_worker_name = new_worker_name
        def file_contains_correct_alias?(full_path, old_worker_name, new_worker_name)
          content = File.read(full_path)
          pattern = /\b#{Regexp.escape(old_worker_name)}\s*=\s*#{Regexp.escape(new_worker_name)}\b/
          content.match?(pattern)
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
          root = root_dir.to_s
          path.start_with?(root) ? path.sub("#{root}/", '').sub(%r{\A/}, '') : path
        end

        def root_dir
          return config.root_dir if config.respond_to?(:root_dir) && config.root_dir

          path = processed_source.file_path.to_s
          dir = File.expand_path(File.dirname(path))
          loop do
            return dir if File.directory?(File.join(dir, '.git'))
            parent = File.dirname(dir)
            break if parent == dir
            dir = parent
          end
          Dir.pwd
        end

        # Returns { renames: [[old_path, new_path], ...] } from git diff --find-renames vs merge target.
        def worker_diff_vs_merge_target
          @worker_diff_vs_merge_target ||= compute_worker_diff_vs_merge_target
        end

        def compute_worker_diff_vs_merge_target
          ref = merge_target_ref
          return nil if ref.nil? || ref.empty?

          root = root_dir.to_s
          return nil unless File.directory?(File.join(root, '.git'))

          merge_base = nil
          Dir.chdir(root) do
            merge_base = `git merge-base HEAD #{ref} 2>/dev/null`.strip
            return nil if merge_base.empty?
          end

          renames = []
          Dir.chdir(root) do
            out = `git diff --name-status --find-renames=50% #{merge_base} HEAD -- app/workers/ 2>/dev/null`
            out.each_line do |line|
              line = line.strip
              next if line.empty?

              next unless line[0] == 'R'

              parts = line[1..].strip.split("\t")
              next unless parts.size >= 2

              old_path = parts[-2].strip
              new_path = parts[-1].strip
              next unless old_path.end_with?(WORKER_SUFFIX) && new_path.end_with?(WORKER_SUFFIX)

              renames << [old_path, new_path]
            end
          end
          { renames: renames }
        rescue StandardError
          @worker_diff_vs_merge_target = { renames: [] }
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
