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

    # ensure the config/database.yml file has the proper configurations
    Rake::Task["apache_age:config_database"].invoke

    # adjust the schema file (unfortunately rails mangles the schema file)
    Rake::Task["apache_age:config_schema"].invoke

    # ensure the config/initializers/types.rb file has the base AGE Types
    Rake::Task["apache_age:config_types"].invoke
  end
end
