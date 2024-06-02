# lib/tasks/install.rake
# Usage: `rake apache_age:install`
#
namespace :apache_age do
  desc "Install & configure Apache Age within Rails (updates migrations, schema & database.yml)"
  task :install => :environment do
    # copy our migrations to the application (if needed)
    Rake::Task["apache_age:copy_migrations"].invoke

    # run any new migrations
    Rake::Task["db:migrate"].invoke

    # adjust the schema file (unfortunately rails mangles the schema file)
    Rake::Task["apache_age:schema_config"].invoke

    # ensure the config/database.yml file has the proper configurations
    Rake::Task["apache_age:database_config"].invoke
  end
end
