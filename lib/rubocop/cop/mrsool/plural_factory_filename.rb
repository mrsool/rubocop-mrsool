# frozen_string_literal: true

module RuboCop
  module Cop
    module Mrsool
      class PluralFactoryFilename < Base
        MSG = 'Factory filename should be singular.'.freeze
        FILENAME_PATTERN = /s_factory\.rb$/.freeze

        def on_new_investigation
          file_path = processed_source.file_path
          return unless file_path.match?(FILENAME_PATTERN)

          factory_name = File.basename(file_path, '.rb')
          singular_form = factory_name.chomp('_factory')
          return if factory_name == singular_form

          src = RuboCop::ProcessedSource.new(processed_source.buffer.source, RUBY_VERSION.to_f)
          add_offense(src.ast, message: MSG)
        end
      end
    end
  end
end
