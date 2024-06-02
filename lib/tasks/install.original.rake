# lib/tasks/install.rake
# Usage: `rake apache_age:install`
#
namespace :apache_age do
  desc "Install & configure Apache Age within Rails (updates migrations, schema & database.yml)"
  task :install_old => :environment do
    source_schema = File.expand_path('../../../db/schema.rb', __FILE__)
    destination_schema = File.expand_path("#{Rails.root}/db/schema.rb", __FILE__)
    source_migrations = File.expand_path('../../../db/migrate', __FILE__)
    destination_migrations = File.expand_path("#{Rails.root}/db/migrate", __FILE__)
    # create the migrations folder if needed
    FileUtils.mkdir_p(destination_migrations) unless File.exist?(destination_migrations)
    original_migrations =
      Dir.glob("#{destination_migrations}/*.rb").map { |file| File.basename(file).sub(/^\d+/, '') }

    # # check if the schema is non-existent or blank (NEW) we need to know how to handle schema
    # is_schema_blank = !File.exist?(destination_schema) || blank_schema?(destination_schema)
    # puts "Schema is blank: #{is_schema_blank}"

    # ensure we have a schema file
    unless File.exist?(destination_schema)
      run_db_create
      run_db_migrate
    end

    # copy our migrations to the application (last_migration_version is nil if no migration necessary)
    # last_migration_version = copy_migrations
    Rake::Task["apache_age:copy_migrations"].invoke

    updated_migrations =
      Dir.glob("#{destination_migrations}/*.rb").map { |file| File.basename(file).sub(/^\d+/, '') }

    # # run our new migrations (unless we have not added any new migrations)
    # if original_migrations == updated_migrations
    #   puts "no new migrations were copied, skipping migrations"
    # else
    #   puts "added Apache Age migrations, running migrations"
    #   run_db_migrate
    # end
    run_db_migrate

    # adjust the schema file (unfortunately rails mangles the schema file)
    # if is_schema_blank
    #   puts "creating new schema..."
    #   create_new_schema(last_migration_version, destination_schema, source_schema)
    # else
    #   puts "updating existing schema..."
    #   update_existing_schema(last_migration_version, destination_schema, source_schema)
    # end
    Rake::Task["apache_age:schema_config"].invoke

    # ensure the config/database.yml file has the proper configurations
    # update_database_yml
    Rake::Task["apache_age:database_config"].invoke
  end

  def run_db_create
    puts "Running db:create..."
    Rake::Task["db:create"].invoke
  end

  def run_db_migrate
    puts "Running db:migrate..."
    Rake::Task["db:migrate"].invoke
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
      (content.include?("enable_extension 'plpgsql'") || content.include?('enable_extension "plpgsql"')) &&
      content.scan(/enable_extension/).size == 1
  end

  def schema_rails_version(destination_schema)
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
      rails_version = schema_rails_version(destination_schema)
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
      rails_version = schema_rails_version(destination_schema)
      source_content = File.read(source_schema)
      new_content =
        source_content.gsub(
          /.*ActiveRecord::Schema\[\d+\.\d+\]\.define\(version: \d{4}(?:_\d{2}){2}(?:_\d{6})?\) do\n|\nend$/,
          ''
        )

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

      # add new wanted schema statements (at the top of the schema)
      unless destination_content.include?(%{execute("LOAD 'age';")}) &&
             destination_content.include?(%{enable_extension 'plpgsql'}) &&
             destination_content.include?(%{execute("SELECT create_graph('age_schema');")}) &&
             destination_content.include?(%{execute('CREATE EXTENSION IF NOT EXISTS age;')}) &&
             destination_content.include?(%{execute('SET search_path = ag_catalog, "$user", public;')})
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
        destination_content.sub!(
          %r{(ActiveRecord::Schema\[\d+\.\d+\]\.define\(version: \d{4}(?:_\d{2}){2}(?:_\d{6})?\) do\n)},
          "\\1#{new_content}\n"
        )
          puts 'db/schema.rb has been updated with the necessary configuration.'
      else
        puts 'db/schema.rb has the necessary configuration, no adjustments necessary'
      end

      existing_version = destination_content.match(/define\(version: (\d{4}(?:_\d{2}){2}(?:_\d{6})?)\)/)[1].gsub('_', '')
      current_version = last_migration_version ? last_migration_version.gsub('_', '') : existing_version

      # ensure we use the last migration version (not the source schema version)
      if current_version.to_i > existing_version.to_i
        destination_content.gsub!(
          /define\(version: \d{4}(?:_\d{2}){2}(?:_\d{6})?\) do/,
          "define(version: #{last_migration_version}) do"
        )
        puts "Updated schema version to the migration version #{last_migration_version}"
      end

      File.write(destination_schema, destination_content)
      puts "Updated #{destination_schema} with necessary extensions and configurations."
    else
      puts "local db/schema.rb file not found."
    end
  end

  def update_database_yml
    db_config_file = File.expand_path("#{Rails.root}/config/database.yml", __FILE__)

    # Read the file
    lines = File.readlines(db_config_file)

    # any uncommented "schema_search_path:" lines?
    path_index = lines.find_index { |line| !line.include?('#') && line.include?('schema_search_path:') }
    default_start_index = lines.index { |line| line.strip.start_with?('default:') }

    # when it finds an existing schema_search_path, it updates it
    if path_index && lines[path_index].include?('ag_catalog,age_schema')
      puts "schema_search_path already set to ag_catalog,age_schema nothing to do."
      return
    elsif path_index
      key, val = lines[path_index].split(': ')
      # remove any unwanted characters
      val = val.gsub(/[ "\s\"\"'\n]/, '')
      lines[path_index] = "#{key}: ag_catalog,age_schema,#{val}\n"
      puts "add ag_catalog,age_schema to schema_search_path"
    elsif default_start_index
      puts "add ag_catalog,age_schema,public to schema_search_path in the default section of database.yml"
      sections_index = lines.map.with_index { |line, index| index if !line.start_with?(' ') }.compact.sort

      # find the start of the default section
      next_section_in_list = sections_index.index(default_start_index) + 1

      # find the end of the default section (before the next section starts)
      path_insert_index = sections_index[next_section_in_list]

      lines.insert(path_insert_index, "  schema_search_path: ag_catalog,age_schema,public\n")
    else
      puts "didn't find a default section in database.yml, please add the following line:"
      puts "  schema_search_path: ag_catalog,age_schema,public"
      puts "to the apprpriate section of your database.yml"
    end

    # Write the modified lines back to the file
    File.open(db_config_file, 'w') { |file| file.write(lines.join) }
  end
end
