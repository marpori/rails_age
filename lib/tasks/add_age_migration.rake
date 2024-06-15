# lib/tasks/install.rake
# Usage:
# * `bin/rails apache_age:add_age_migration`
# * `bin/rails  apache_age:add_age_migration[destination_path.to_s]`
# * `bundle exec rails apache_age:add_age_migration.invoke(destination_path.to_s)`
namespace :apache_age do
  desc "Copy migrations from rails_age to application and update schema"
  task :add_age_migration, [:destination_path] => :environment do |t, args|

    base_name = 'add_apache_age'
    destination_path =
      File.expand_path(args[:destination_path].presence || "#{Rails.root}/db/migrate", __FILE__)

    FileUtils.mkdir_p(destination_path) unless File.exist?(destination_path)
    existing_migrations =
      Dir.glob("#{destination_path}/*.rb").map { |file| File.basename(file).sub(/^\d+/, '') }

    if existing_migrations.any? { |migration| migration.include?(base_name) }
      puts "Skipping migration AddApacheAge, it already exists"
    else
      age_migration_contents =
        <<~RUBY
        class AddApacheAge < ActiveRecord::Migration[7.1]
          def up
            # Allow age extension
            execute('CREATE EXTENSION IF NOT EXISTS age;')

            # Load the age code
            execute("LOAD 'age';")

            # Load the ag_catalog into the search path
            execute('SET search_path = ag_catalog, "$user", public;')

            # Create age_schema graph if it doesn't exist
            execute("SELECT create_graph('age_schema');")
          end

          def down
            execute <<-SQL
              DO $$
              BEGIN
                IF EXISTS (
                  SELECT 1
                  FROM pg_constraint
                  WHERE conname = 'fk_graph_oid'
                ) THEN
                  ALTER TABLE ag_catalog.ag_label
                  DROP CONSTRAINT fk_graph_oid;
                END IF;
              END $$;
            SQL

            execute("SELECT drop_graph('age_schema', true);")
            execute('DROP SCHEMA IF EXISTS ag_catalog CASCADE;')
            execute('DROP EXTENSION IF EXISTS age;')
          end
        end
        RUBY

      migration_version = Time.now.utc.strftime("%Y%m%d%H%M%S")
      file_version = migration_version.delete('_')
      new_filename = "#{file_version}_#{base_name}.rb"
      destination_file = File.join(destination_path, new_filename)

      File.write(destination_file, age_migration_contents)
      puts "Created migration AddApacheAge"
    end
  end
end
