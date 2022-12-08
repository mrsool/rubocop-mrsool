# frozen_string_literal: true

module RuboCop
  module Cop
    module Mrsool
      class DbMigrationTimestamp < Base
        MSG = "Migration timestamp must be inserted into `schema_migrations` in db/structure.sql"

        def self.added_timestamps
          @schema_source ||=
            begin
              sql = IO.read("db/structure.sql")
              _, versions = sql.split("INSERT INTO `schema_migrations` (version) VALUES")
              versions
            end
        end

        def on_new_investigation
          file_path = processed_source.file_path

          return unless file_path.include?("db/migrate/")

          timestamp, _ = File.basename(file_path).split("_", 2)

          return if self.class.added_timestamps.include?(timestamp)

          src = RuboCop::ProcessedSource.new(processed_source.buffer.source, RUBY_VERSION.to_f)
          add_offense(src.ast, message: MSG)
        end
      end
    end
  end
end
