# lib/tasks/install.rake
# Usage: `rake apache_age:schema_config`
#
namespace :apache_age do
  desc "Copy migrations from rails_age to application and update schema"
  task :config_schema => :environment do
    destination_schema = File.expand_path("#{Rails.root}/db/schema.rb", __FILE__)

    unless File.exist?(destination_schema)
      puts "local db/schema.rb file not found. please run db:create and db:migrate first"
    else
      destination_content = File.read(destination_schema)

      # Remove unwanted schema statements
      destination_content.gsub!(%r{^.*?create_schema "ag_catalog".*?\n}, '')
      destination_content.gsub!(%r{^.*?create_schema "age_schema".*?\n}, '')
      destination_content.gsub!(%r{^.*?enable_extension "age".*?\n}, '')
      destination_content.gsub!(%r{^.*?enable_extension "plpgsql".*?\n}, '')
      destination_content.gsub!(%r{^.*?# Could not dump table "ag_graph" because of following StandardError.*?\n}, '')
      destination_content.gsub!(%r{^.*?#   Unknown type 'regnamespace' for column 'namespace'.*?\n}, '')
      destination_content.gsub!(%r{^.*?# Could not dump table "ag_label" because of following StandardError.*?\n}, '')
      destination_content.gsub!(%r{^.*?#   Unknown type 'regclass' for column 'relation'.*?\n}, '')
      destination_content.gsub!(%r{^.*?#   Unknown type 'graphid' for column 'id'.*?\n}, '')
      destination_content.gsub!(
        %r{^.*?# Could not dump table "_ag_label_edge" because of following StandardError.*?\n}, ''
      )
      destination_content.gsub!(
        %r{^.*?# Could not dump table "_ag_label_vertex" because of following StandardError.*?\n}, ''
      )
      destination_content.gsub!(%r{^.*?# Could not dump table "ag_graph" because of following StandardError.*?\n}, '')
      destination_content.gsub!(%r{^.*?# Could not dump table "ag_label" because of following StandardError.*?\n}, '')
      destination_content.gsub!(%r{^.*?add_foreign_key "ag_label", "ag_graph".*?\n}, '')

      # add necessary contents (as needed)
      if destination_content.include?(%{execute("LOAD 'age';")}) &&
              destination_content.include?(%{enable_extension 'plpgsql'}) &&
              destination_content.include?(%{execute("SELECT create_graph('age_schema');")}) &&
              destination_content.include?(%{execute('CREATE EXTENSION IF NOT EXISTS age;')}) &&
              destination_content.include?(%{execute('SET search_path = ag_catalog, "$user", public;')})
        puts "schema.rb is properly configured, nothing to do"
      else
        # if not all are found then remove any found
        destination_content.gsub!(%r{^.*?execute("LOAD 'age';")*?\n}, '')
        destination_content.gsub!(%r{^.*?enable_extension 'plpgsql'*?\n}, '')
        destination_content.gsub!(%r{^.*?execute("SELECT create_graph('age_schema');")*?\n}, '')
        destination_content.gsub!(%r{^.*?execute('CREATE EXTENSION IF NOT EXISTS age;')*?\n}, '')
        destination_content.gsub!(%r{^.*?execute('SET search_path = ag_catalog, "$user", public;')*?\n}, '')
        destination_content.gsub!(%r{^.*?# Allow age extension*?\n}, '')
        destination_content.gsub!(%r{^.*?# Load the ag_catalog into the search path*?\n}, '')
        destination_content.gsub!(%r{^.*?# Create age_schema graph if it doesn't exist*?\n}, '')
        destination_content.gsub!(%r{^.*?# These are extensions that must be enabled in order to support this database*?\n}, '')

        # add all of the correct settings back in
        # source_content = File.read(source_schema)
        source_content =
          <<~RUBY
          ActiveRecord::Schema[7.1].define(version: 2024_05_21_062349) do
            # These are extensions that must be enabled in order to support this database
            enable_extension 'plpgsql'

            # Allow age extension
            execute('CREATE EXTENSION IF NOT EXISTS age;')

            # Load the age code
            execute("LOAD 'age';")

            # Load the ag_catalog into the search path
            execute('SET search_path = ag_catalog, "$user", public;')

            # Create age_schema graph if it doesn't exist
            execute("SELECT create_graph('age_schema');")
          end
          RUBY

        age_config_contents =
          source_content.gsub(
            /.*ActiveRecord::Schema\[\d+\.\d+\]\.define\(version: \d{4}(?:_\d{2}){2}(?:_\d{6})?\) do\n|\nend$/,
            ''
          )

        destination_content.sub!(
          %r{(ActiveRecord::Schema\[\d+\.\d+\]\.define\(version: \d{4}(?:_\d{2}){2}(?:_\d{6})?\) do\n)},
          "\\1#{age_config_contents}\n"
        )
      end

      # Remove multiple consecutive empty lines
      destination_content.gsub!(/\n{2,}/, "\n\n")

      File.write(destination_schema, destination_content)
      puts "The schema '#{destination_schema}' is ready to work with Apache Age."
    end
  end
end
