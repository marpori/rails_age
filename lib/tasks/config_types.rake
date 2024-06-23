# lib/tasks/install.rake
# Usage: `rake apache_age:config_types`
#
namespace :apache_age do
  desc "Install AGE types from rails_age into the rails initializers"
  task :config_types => :environment do
    types_file_path = File.expand_path("#{Rails.root}/config/initializers/types.rb", __FILE__)
    required_file_path = "require 'apache_age/types/factory'"
    required_file_content =
      <<~RUBY
      require 'apache_age/types/factory'
      # AGE Type Definition Usage (edges/nodes):
      # require_dependency 'nodes/company'
      # ActiveModel::Type.register(
      #   :company, ApacheAge::Types::Factory.create_type_for(Nodes::Company)
      # )
      RUBY
    node_type_content =
<<-RUBY
  require_dependency 'apache_age/node'
  ActiveModel::Type.register(
    :node, ApacheAge::Types::Factory.create_type_for(ApacheAge::Node)
  )
RUBY
    edge_type_content =
<<-RUBY
  require_dependency 'apache_age/edge'
  ActiveModel::Type.register(
    :edge, ApacheAge::Types::Factory.create_type_for(ApacheAge::Edge)
  )
RUBY

    unless File.exist?(types_file_path)
      source_content =
        <<~RUBY
        # config/initializers/types.rb

        #{required_file_content}
        Rails.application.config.to_prepare do
          # Register AGE types
        #{node_type_content}
        #{edge_type_content}
        end
        RUBY
      File.open(types_file_path, 'w') { |file| file.write(source_content) }
      puts "config/initializers/types.rb file created with AGE base types"
    else
      destination_content = File.read(types_file_path)
      original_content = destination_content.dup

      unless destination_content.include?(required_file_path)
        destination_content.sub!(
          /^(\s*Rails\.application\.config\.to_prepare do\n)/,
          "#{required_file_content}\n\\1"
        )
      end

      unless destination_content.include?('# Register AGE types')
        destination_content.sub!(
          /^(\s*Rails\.application\.config\.to_prepare do\n)/,
          "\\1  # Register AGE types\n"
        )
      end

      unless destination_content.include?(edge_type_content)
        destination_content.sub!(
          /^(\s*Rails\.application\.config\.to_prepare do\n  # Register AGE types\n)/,
          "\\1#{edge_type_content}"
        )
      end

      unless destination_content.include?(node_type_content)
        destination_content.sub!(
          /^(\s*Rails\.application\.config\.to_prepare do\n  # Register AGE types\n)/,
          "\\1#{node_type_content}"
        )
      end

      if destination_content != original_content
        File.open(types_file_path, 'w') { |file| file.write(destination_content) }
        puts "modified: config/initializers/types.rb"
      end
    end
  end
end
