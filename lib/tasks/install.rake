# lib/tasks/install.rake
# Usage: `rake rails_age:install`
#
namespace :rails_age do
  desc "Copy migrations from rails_age to application and update schema"
  task :install => :environment do
    source_schema = File.expand_path('../../../db/schema.rb', __FILE__)
    destination_schema = File.expand_path("#{Rails.root}/db/schema.rb", __FILE__)

    # ensure we have a schema file
    run_migrations

    # copy our migrations to the application
    last_migration_version = copy_migrations

    # check if the schema is blank (NEW) before running migrations!
    is_schema_blank = blank_schema?(destination_schema)
    puts "Schema is blank: #{is_schema_blank}"

    # run our new migrations
    run_migrations

    # adjust the schema file (unfortunately rails mangles the schema file)
    if is_schema_blank
      puts "creating new schema..."
      create_new_schema(last_migration_version, destination_schema, source_schema)
    else
      puts "updating existing schema..."
      update_existing_schema(last_migration_version, destination_schema, source_schema)
    end
  end

  def copy_migrations
    migration_version = nil

    source = File.expand_path('../../../db/migrate', __FILE__)
    destination = File.expand_path("#{Rails.root}/db/migrate", __FILE__)

    FileUtils.mkdir_p(destination) unless File.exist?(destination)
    existing_migrations =
      Dir.glob("#{destination}/*.rb").map { |file| File.basename(file).sub(/^\d+/, '') }

    Dir.glob("#{source}/*.rb").each do |file|
      filename = File.basename(file)
      test_name = filename.sub(/^\d+/, '')

      if existing_migrations.include?(test_name)
        puts "Skipping #{filename}, it already exists"
      else
        migration_version = Time.now.utc.strftime("%Y_%m_%d_%H%M%S")
        file_version = migration_version.delete('_')
        new_filename = filename.sub(/^\d+/, file_version)
        destination_file = File.join(destination, new_filename)
        FileUtils.cp(file, destination_file)
        puts "Copied #{filename} to #{destination} as #{new_filename}"
      end
    end
    migration_version
  end

  def blank_schema?(destination_schema)
    return false unless File.exist?(destination_schema)

    content = File.read(destination_schema)
    content.include?('define(version: 0)') &&
      content.include?('enable_extension "plpgsql"') &&
      content.scan(/enable_extension/).size == 1
  end

  def run_migrations
    puts "Running migrations..."
    Rake::Task["db:migrate"].invoke
  end

  def extract_rails_version(destination_schema)
    if File.exist?(destination_schema)
      content = File.read(destination_schema)
      version_match = content.match(/ActiveRecord::Schema\[(.*?)\]/)
      return version_match[1] if version_match
    else
      full_version = Rails.version
      primary_secondary_version = full_version.split('.')[0..1].join('.')
      primary_secondary_version
    end
  end

  def create_new_schema(last_migration_version, destination_schema, source_schema)
    if File.exist?(source_schema) && File.exist?(destination_schema)
      rails_version = extract_rails_version(destination_schema)
      source_content = File.read(source_schema)

      # ensure we use the Rails version from the destination schema
      source_content.gsub!(
        /ActiveRecord::Schema\[\d+\.\d+\]/,
        "ActiveRecord::Schema[#{rails_version}]"
      )
      # ensure we use the last migration version (not the source schema version)
      source_content.gsub!(
        /define\(version: \d{4}(?:_\d{2}){2}(?:_\d{6})?\) do/,
        "define(version: #{last_migration_version}) do"
      )

      File.write(destination_schema, source_content)
      puts "Created new schema in #{destination_schema} with necessary extensions and configurations."
    else
      puts "local db/schema.rb file not found."
    end
  end

  def update_existing_schema(last_migration_version, destination_schema, source_schema)
    if File.exist?(source_schema) && File.exist?(destination_schema)
      rails_version = extract_rails_version(destination_schema)
      source_content = File.read(source_schema)
      new_content =
        source_content.gsub(
          /.*ActiveRecord::Schema\[\d+\.\d+\]\.define\(version: \d{4}(?:_\d{2}){2}(?:_\d{6})?\) do\n|\nend$/,
          ''
        )

      destination_content = File.read(destination_schema)

      # Remove unwanted schema statements
      destination_content.gsub!(%r{^.*?# These are extensions that must be enabled in order to support this database.*?\n}, '')

      destination_content.gsub!(%r{^.*?create_schema "ag_catalog".*?\n}, '')
      destination_content.gsub!(%r{^.*?create_schema "age_schema".*?\n}, '')
      destination_content.gsub!(%r{^.*?enable_extension "age".*?\n}, '')
      destination_content.gsub!(%r{^.*?enable_extension "plpgsql".*?\n}, '')
      destination_content.gsub!(%r{^.*?# Could not dump table "ag_graph" because of following StandardError.*?\n}, '')
      destination_content.gsub!(%r{^.*?#   Unknown type 'regnamespace' for column 'namespace'.*?\n}, '')
      destination_content.gsub!(%r{^.*?# Could not dump table "ag_label" because of following StandardError.*?\n}, '')
      destination_content.gsub!(%r{^.*?#   Unknown type 'regclass' for column 'relation'.*?\n}, '')
      destination_content.gsub!(
        %r{^.*?# Could not dump table "_ag_label_edge" because of following StandardError.*?\n}, ''
      )
      destination_content.gsub!(
        %r{^.*?# Could not dump table "_ag_label_vertex" because of following StandardError.*?\n}, ''
      )
      destination_content.gsub!(%r{^.*?# Could not dump table "ag_graph" because of following StandardError.*?\n}, '')
      destination_content.gsub!(%r{^.*?# Could not dump table "ag_label" because of following StandardError.*?\n}, '')
      destination_content.gsub!(%r{^.*?add_foreign_key "ag_label", "ag_graph".*?\n}, '')

      # add new wanted schema statements (at the top of the schema)
      destination_content.sub!(
        %r{(ActiveRecord::Schema\[\d+\.\d+\]\.define\(version: \d{4}(?:_\d{2}){2}(?:_\d{6})?\) do\n)},
        "\\1#{new_content}\n"
      )

      existing_version = destination_content.match(/define\(version: (\d{4}(?:_\d{2}){2}(?:_\d{6})?)\)/)[1].gsub('_', '')
      current_version = last_migration_version ? last_migration_version.gsub('_', '') : existing_version

      # ensure we use the last migration version (not the source schema version)
      if current_version.to_i > existing_version.to_i
        destination_content.gsub!(
          /define\(version: \d{4}(?:_\d{2}){2}(?:_\d{6})?\) do/,
          "define(version: #{last_migration_version}) do"
        )
      end

      File.write(destination_schema, destination_content)
      puts "Updated #{destination_schema} with necessary extensions and configurations."
    else
      puts "local db/schema.rb file not found."
    end
  end

  # # Update the schema.rb file
  # def update_schema
  #   schema_file = File.expand_path("#{Rails.root}/db/schema.rb", __FILE__)
  #   if File.exist?(schema_file)
  #     content = File.read(schema_file)
  #     # Add the necessary extensions and configurations at the top of the schema
  #     insert_statements = <<-RUBY

  # # These are extensions that must be enabled in order to support this database
  # enable_extension 'plpgsql'

  # # Allow age extension
  # execute('CREATE EXTENSION IF NOT EXISTS age;')

  # # Load the age code
  # execute("LOAD 'age';")

  # # Load the ag_catalog into the search path
  # execute('SET search_path = ag_catalog, "$user", public;')

  # # Create age_schema graph if it doesn't exist
  # execute("SELECT create_graph('age_schema');")

  #     RUBY
  #     unless content.include?(insert_statements.strip)
  #       content.sub!(/^# These are extensions that must be enabled in order to support this database.*?\n\n/m, insert_statements)
  #     end
  #     # Remove unwanted schema statements
  #     content.gsub!(/^.*?create_schema "ag_catalog".*?\n\n/m, '')
  #     content.gsub!(/^.*?create_schema "age_schema".*?\n\n/m, '')
  #     content.gsub!(/^.*?enable_extension "age".*?\n\n/m, '')
  #     content.gsub!(/^.*?# Could not dump table "_ag_label_edge" because of following StandardError.*?\n\n/m, '')
  #     content.gsub!(/^.*?# Could not dump table "_ag_label_vertex" because of following StandardError.*?\n\n/m, '')
  #     content.gsub!(/^.*?# Could not dump table "ag_graph" because of following StandardError.*?\n\n/m, '')
  #     content.gsub!(/^.*?# Could not dump table "ag_label" because of following StandardError.*?\n\n/m, '')
  #     content.gsub!(/^.*?add_foreign_key "ag_label", "ag_graph".*?\n\n/m, '')

  #     File.write(schema_file, content)
  #     puts "Updated #{schema_file} with necessary extensions and configurations."
  #   else
  #     puts "schema.rb file not found. Please ensure migrations have been run."
  #   end
  # end
end
