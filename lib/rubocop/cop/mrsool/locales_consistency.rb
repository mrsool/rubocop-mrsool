# frozen_string_literal: true

require 'yaml'
require 'set'

module RuboCop
  module Cop
    module Mrsool
      # Checks for consistency of translation keys across locale files.
      # Ensures that when a key is added to one locale file, it exists in equivalent
      # files for all supported languages.
      class LocalesConsistency < Base
        MSG = 'Missing translation key "%<key>s" in locale files: %<missing_files>s'

        # Supported languages
        SUPPORTED_LANGUAGES = %w[en ar ur bn hi].freeze

        def on_new_investigation
          file_path = processed_source.file_path
          return unless locale_file?(file_path)

          current_keys = extract_keys_from_yaml(processed_source.buffer.source)
          return if current_keys.empty?

          equivalent_files = find_equivalent_files(file_path)
          return if equivalent_files.empty?

          equivalent_file_keys = cache_equivalent_file_keys(equivalent_files)
          missing_keys = find_missing_keys(current_keys, equivalent_file_keys)
          return if missing_keys.empty?

          report_missing_keys(missing_keys)
        end

        private

        def locale_file?(file_path)
          file_path.include?('config/locales/') && file_path.end_with?('.yml')
        end

        def extract_keys_from_yaml(yaml_content)
          return [] unless yaml_content

          begin
            yaml_data = YAML.safe_load(yaml_content, aliases: true)
            return [] unless yaml_data.is_a?(Hash)

            extract_nested_keys(yaml_data)
          rescue Psych::SyntaxError, Psych::DisallowedClass
            []
          end
        end

        def extract_nested_keys(hash, prefix = '')
          keys = []
          hash.each do |key, value|
            current_key = prefix.empty? ? key.to_s : "#{prefix}.#{key}"

            if prefix.empty? && SUPPORTED_LANGUAGES.include?(key.to_s)
              extract_language_root_keys(value, keys)
            else
              extract_regular_keys(value, current_key, keys)
            end
          end
          keys
        end

        def find_equivalent_files(file_path)
          equivalent_files = []
          base_path = extract_base_path(file_path)
          current_lang = extract_language(file_path)

          return equivalent_files if current_lang.nil?

          SUPPORTED_LANGUAGES.each do |lang|
            next if lang == current_lang

            equivalent_file = build_equivalent_file_path(base_path, lang)
            equivalent_files << equivalent_file if File.exist?(equivalent_file)
          end

          equivalent_files
        end

        def extract_base_path(file_path)
          path_without_ext = file_path.gsub(/\.yml$/, '')
          filename = File.basename(path_without_ext)
          dirname = File.dirname(path_without_ext)

          SUPPORTED_LANGUAGES.each do |lang|
            if filename.end_with?("_#{lang}") || filename == lang
              filename = filename.gsub(/_#{lang}$/, '').gsub(/^#{lang}$/, '')
              break
            end
          end

          filename.empty? ? dirname : File.join(dirname, filename)
        end

        def extract_language(file_path)
          # Extract language from filename
          # e.g., "banners_en.yml" -> "en"
          # e.g., "ar.yml" -> "ar"
          filename = File.basename(file_path, '.yml')

          SUPPORTED_LANGUAGES.find do |lang|
            # Check both suffixed pattern (banners_en.yml) AND simple language file (en.yml)
            filename.end_with?("_#{lang}") || filename == lang
          end
        end

        def build_equivalent_file_path(base_path, language)
          # Handle two cases:
          # 1. Directory-based: config/locales/en.yml -> config/locales/ar.yml
          # 2. Suffix-based: config/locales/test/banners_en.yml -> config/locales/test/banners_ar.yml

          # Check if base_path ends with a directory separator
          if base_path.end_with?('/') || File.directory?(base_path)
            # Directory-based: append language.yml
            File.join(base_path, "#{language}.yml")
          else
            # Suffix-based: append _language.yml
            "#{base_path}_#{language}.yml"
          end
        end

        def cache_equivalent_file_keys(equivalent_files)
          equivalent_file_keys = {}

          equivalent_files.each do |file_path|
            next unless File.exist?(file_path)

            equivalent_file_keys[file_path] = extract_keys_from_file(file_path)
          end

          equivalent_file_keys
        end

        def extract_keys_from_file(file_path)
          yaml_content = File.read(file_path)
          yaml_data = YAML.safe_load(yaml_content, aliases: true)
          return Set.new unless yaml_data.is_a?(Hash)

          all_keys = extract_nested_keys(yaml_data)
          Set.new(all_keys)
        rescue Psych::SyntaxError, Psych::DisallowedClass
          Set.new
        end

        def find_missing_keys(current_keys, equivalent_file_keys)
          missing_keys = {}

          current_keys.each do |key|
            missing_files = []

            equivalent_file_keys.each do |file_path, keys_set|
              missing_files << file_path unless keys_set.include?(key)
            end

            missing_keys[key] = missing_files unless missing_files.empty?
          end

          missing_keys
        end

        def key_exists_in_hash?(key, hash)
          keys = key.split('.')
          current = hash

          keys.each do |k|
            return false unless current.is_a?(Hash) && current.key?(k)

            current = current[k]
          end

          true
        end

        def report_missing_keys(missing_keys)
          missing_keys.each do |key, missing_files|
            message = format(MSG, key: key, missing_files: missing_files.join(', '))
            add_offense_for_missing_key(message)
          end
        end

        def add_offense_for_missing_key(message)
          @offenses ||= []
          @offenses << RuboCop::Cop::Offense.new(
            :convention,
            nil,
            message,
            'Mrsool/LocalesConsistency',
            :convention
          )
        end

        def extract_language_root_keys(value, keys)
          return unless value.is_a?(Hash)

          value.each do |child_key, child_value|
            child_current_key = child_key.to_s
            if child_value.is_a?(Hash)
              keys.concat(extract_nested_keys(child_value, child_current_key))
            else
              keys << child_current_key
            end
          end
        end

        def extract_regular_keys(value, current_key, keys)
          if value.is_a?(Hash)
            keys.concat(extract_nested_keys(value, current_key))
          else
            keys << current_key
          end
        end
      end
    end
  end
end
