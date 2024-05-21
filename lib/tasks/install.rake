# lib/tasks/install.rake
# Usage: `rake rails_age:install`
#
namespace :rails_age do
  desc "Copy migrations from rails_age to application and update schema"
  task :install => :environment do
    source = File.expand_path('../../../db/migrate', __FILE__)
    destination = File.expand_path('../../../../db/migrate', __FILE__)

    FileUtils.mkdir_p(destination) unless File.exists?(destination)

    Dir.glob("#{source}/*.rb").each do |file|
      filename = File.basename(file)
      destination_file = File.join(destination, filename)

      if File.exists?(destination_file)
        puts "Skipping #{filename}, it already exists"
      else
        FileUtils.cp(file, destination_file)
        puts "Copied #{filename} to #{destination}"
      end
    end

    # Update the schema.rb file
    schema_file = File.expand_path('../../../../db/schema.rb', __FILE__)
    if File.exists?(schema_file)
      content = File.read(schema_file)

      # Add the necessary extensions and configurations at the top of the schema
      insert_statements = <<-RUBY

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  # Allow age extension
  execute('CREATE EXTENSION IF NOT EXISTS age;')

  # Load the age code
  execute("LOAD 'age';")

  # Load the ag_catalog into the search path
  execute('SET search_path = ag_catalog, "$user", public;')

  # Create age_schema graph if it doesn't exist
  execute("SELECT create_graph('age_schema');")

      RUBY

      unless content.include?(insert_statements.strip)
        content.sub!(/^# These are extensions that must be enabled in order to support this database.*?\n\n/m, insert_statements)
      end

      # Remove unwanted schema statements
      content.gsub!(/^.*?create_schema "ag_catalog".*?\n\n/m, '')
      content.gsub!(/^.*?create_schema "age_schema".*?\n\n/m, '')
      content.gsub!(/^.*?enable_extension "age".*?\n\n/m, '')
      content.gsub!(/^.*?# Could not dump table "_ag_label_edge" because of following StandardError.*?\n\n/m, '')
      content.gsub!(/^.*?# Could not dump table "_ag_label_vertex" because of following StandardError.*?\n\n/m, '')
      content.gsub!(/^.*?# Could not dump table "ag_graph" because of following StandardError.*?\n\n/m, '')
      content.gsub!(/^.*?# Could not dump table "ag_label" because of following StandardError.*?\n\n/m, '')
      content.gsub!(/^.*?add_foreign_key "ag_label", "ag_graph".*?\n\n/m, '')

      File.write(schema_file, content)
      puts "Updated #{schema_file} with necessary extensions and configurations."
    else
      puts "schema.rb file not found. Please ensure migrations have been run."
    end
  end
end

# namespace :rails_age do
#   desc "Copy migrations from rails_age to application"
#   task :install => :environment do
#     source = File.expand_path('../../../db/migrate', __FILE__)
#     destination = File.expand_path('../../../../db/migrate', __FILE__)

#     FileUtils.mkdir_p(destination) unless File.exists?(destination)

#     Dir.glob("#{source}/*.rb").each do |file|
#       filename = File.basename(file)
#       destination_file = File.join(destination, filename)

#       if File.exists?(destination_file)
#         puts "Skipping #{filename}, it already exists"
#       else
#         FileUtils.cp(file, destination_file)
#         puts "Copied #{filename} to #{destination}"
#       end
#     end
#   end
# end
