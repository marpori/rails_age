namespace :apache_age do
  desc "Ensure 'db:migrate' is followed by 'apache_age:config_schema' to repair 'schema.rb' after migrations"
  task :migrate do
    Rake::Task['db:migrate'].invoke
    Rake::Task["apache_age:config_schema"].invoke
  end
end
