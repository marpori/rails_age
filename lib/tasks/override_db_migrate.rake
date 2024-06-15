namespace :apache_age do
  desc "Ensure 'db:migrate' is followed by 'apache_age:config_schema' to repair the schema.rb file after migration mangles it."
  task :override_db_migrate, [:destination_path] => :environment do |t, args|
    destination_path = (args[:destination_path].presence || "#{Rails.root}") + "/bin"
    FileUtils.mkdir_p(destination_path) unless File.exist?(destination_path)
    bin_rails_path = File.expand_path("#{destination_path}/rails", __FILE__)

    original_content = File.read(bin_rails_path)
    destination_content = original_content.dup

    unless destination_content.include?("#!/usr/bin/env ruby\nrails_cmd = ARGV.first")
      capture_rails_cmd =
        <<~RUBY
        rails_cmd = ARGV.first # must be first (otherwise consumed by rails:commands)
        RUBY

      # add to the top of the file (with gsub)
      destination_content.sub!(
        %r{#!/usr/bin/env ruby\n},
        "#!/usr/bin/env ruby\n#{capture_rails_cmd}\n"
      )
    end

    # Check if the migration hook is already present
    unless destination_content.include?('Rake::Task["apache_age:config_schema"].invoke')
      override_migrate =
        <<~RUBY

        # ensure db:migrate is followed with: `Rake::Task["apache_age:config_schema"].invoke`
        # to the schema.rb file after the migration mangles it
        if rails_cmd == 'db:migrate'
          require 'rake'
          Rails.application.load_tasks
          Rake::Task['db:migrate'].invoke
          Rake::Task["apache_age:config_schema"].invoke
        end
        RUBY

      # append to the end of the file
      destination_content << override_migrate
    end

    if destination_content == original_content
      puts "AGE Safe Migration is already present in bin/rails. (If its not working inspect the bin/rails file)"
    else
      File.write(bin_rails_path, destination_content)
      puts "AGE Safe Migration added to bin/rails. Now run `bin/rails db:migrate`, then run your tests (or inspect the schema.rb file)."
    end
  end
end
