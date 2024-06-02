# lib/tasks/install.rake
# Usage:
# * `bin/rails apache_age:copy_migrations`
# * `bundle exec rails apache_age:copy_migrations[destination_path.to_s]`
# * `bundle exec rails apache_age:copy_migrations.invoke(destination_path.to_s)`
namespace :apache_age do
  desc "Copy migrations from rails_age to application and update schema"
  task :copy_migrations, [:destination_path] => :environment do |t, args|
    source = File.expand_path('../../../db/migrate', __FILE__)
    destination_path =
      File.expand_path(args[:destination_path].presence || "#{Rails.root}/db/migrate", __FILE__)

    FileUtils.mkdir_p(destination_path) unless File.exist?(destination_path)
    existing_migrations =
      Dir.glob("#{destination_path}/*.rb").map { |file| File.basename(file).sub(/^\d+/, '') }

    Dir.glob("#{source}/*.rb").each do |file|
      filename = File.basename(file)
      test_name = filename.sub(/^\d+/, '')

      if existing_migrations.include?(test_name)
        puts "Skipping migration: '#{filename}', it already exists"
      else
        migration_version = Time.now.utc.strftime("%Y_%m_%d_%H%M%S")
        file_version = migration_version.delete('_')
        new_filename = filename.sub(/^\d+/, file_version)
        destination_file = File.join(destination_path, new_filename)
        FileUtils.cp(file, destination_file)
        puts "Created migration: '#{new_filename}'"
      end
    end
  end
end
