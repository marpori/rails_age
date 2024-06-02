# lib/tasks/install.rake
# Usage: `rake apache_age:copy_migrations`
#
namespace :apache_age do
  desc "Ensure the database.yml file is properly configured for Apache Age"
  task :database_config => :environment do

    db_config_file = File.expand_path("#{Rails.root}/config/database.yml", __FILE__)

    # Read the file
    lines = File.readlines(db_config_file)

    # any uncommented "schema_search_path:" lines?
    path_index = lines.find_index { |line| !line.include?('#') && line.include?('schema_search_path:') }
    default_start_index = lines.index { |line| line.strip.start_with?('default:') }

    # when it finds an existing schema_search_path, it updates it
    if path_index && lines[path_index].include?('ag_catalog,age_schema')
      puts "the schema_search_path in config/database.yml is already properly set, nothing to do."
    else
      if path_index
        key, val = lines[path_index].split(': ')
        # remove any unwanted characters
        val = val.gsub(/[ "\s\"\"'\n]/, '')
        lines[path_index] = "#{key}: ag_catalog,age_schema,#{val}\n"
        puts "added ag_catalog,age_schema to schema_search_path in config/database.yml"
      elsif default_start_index
        puts "the schema_search_path in config/database.yml is now properly set."
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
end

# # lib/tasks/install.rake
# # Usage: `rake apache_age:copy_migrations`
# #
# namespace :apache_age do
#   desc "Ensure the database.yml file is properly configured for Apache Age"
#   task :database_config, [:destination_path] => :environment do |t, args|
#     destination_path =
#       File.expand_path(args[:destination_path].presence || "#{Rails.root}/config", __FILE__)

#     db_config_file = File.expand_path("#{destination_path.to_s}/database.yml", __FILE__)

#     # Read the file
#     lines = File.readlines(db_config_file)

#     # any uncommented "schema_search_path:" lines?
#     path_index = lines.find_index { |line| !line.include?('#') && line.include?('schema_search_path:') }
#     default_start_index = lines.index { |line| line.strip.start_with?('default:') }

#     # when it finds an existing schema_search_path, it updates it
#     if path_index && lines[path_index].include?('ag_catalog,age_schema')
#       puts "the schema_search_path in config/database.yml is already properly set, nothing to do."
#     else
#       if path_index
#         key, val = lines[path_index].split(': ')
#         # remove any unwanted characters
#         val = val.gsub(/[ "\s\"\"'\n]/, '')
#         lines[path_index] = "#{key}: ag_catalog,age_schema,#{val}\n"
#         puts "added ag_catalog,age_schema to schema_search_path in config/database.yml"
#       elsif default_start_index
#         puts "the schema_search_path in config/database.yml is now properly set."
#         sections_index = lines.map.with_index { |line, index| index if !line.start_with?(' ') }.compact.sort

#         # find the start of the default section
#         next_section_in_list = sections_index.index(default_start_index) + 1

#         # find the end of the default section (before the next section starts)
#         path_insert_index = sections_index[next_section_in_list]

#         lines.insert(path_insert_index, "  schema_search_path: ag_catalog,age_schema,public\n")
#       else
#         puts "didn't find a default section in database.yml, please add the following line:"
#         puts "  schema_search_path: ag_catalog,age_schema,public"
#         puts "to the apprpriate section of your database.yml"
#       end

#       # Write the modified lines back to the file
#       File.open(db_config_file, 'w') { |file| file.write(lines.join) }
#     end
#   end
# end
