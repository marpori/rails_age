# lib/tasks/install.rake
# Usage: `rake apache_age:config_types`
#
namespace :apache_age do
  desc "Install AGE types from rails_age into the rails initializers"
  task :config_types => :environment do
    types_file_path =
      File.expand_path("#{Rails.root}/config/initializers/types.rb", __FILE__)
    required_file_path = "require 'apache_age/types/age_type_generator'"
    reqired_file_content =
      <<~RUBY
      require 'apache_age/types/age_type_generator'
      # AGE Type Definition Usage (edges/nodes):
      # require_dependency 'nodes/company'
      # ActiveModel::Type.register(
      #   :company, ApacheAge::Types::AgeTypeGenerator.create_type_for(Nodes::Company)
      # )
      RUBY
    node_type_content =
      <<~RUBY
        require_dependency 'apache_age/entities/vertex'
        ActiveModel::Type.register(
          :vertex, ApacheAge::Types::AgeTypeGenerator.create_type_for(ApacheAge::Entities::Vertex)
        )
      RUBY
    edge_type_content =
      <<~RUBY
        require_dependency 'apache_age/entities/edge'
        ActiveModel::Type.register(
          :edge, ApacheAge::Types::AgeTypeGenerator.create_type_for(ApacheAge::Entities::Edge)
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

      if destination_content.exclude?(required_file_path)
        destination_content =
          destination_content.gsub(
            "Rails.application.config.to_prepare do",
            "#{required_file_path}\n\nRails.application.config.to_prepare do"
          )
          puts "adding `require_dependency 'apache_age/entities/edge'` to the " \
               "top of 'config/initializers/types.rb'"
      end

      if destination_content.exclude?('# Register AGE types')
        destination_content.gsub(
            "Rails.application.config.to_prepare do",
            "Rails.application.config.to_prepare do\n  # Register AGE types"
          )
        puts "adding comment to the config of 'config/initializers/types.rb'"
      end

      if destination_content.exclude?(edge_type_content)
        destination_content.gsub(
          "Rails.application.config.to_prepare do\n  # Register AGE types",
          "Rails.application.config.to_prepare do\n  # Register AGE types\n  #{edge_type_content}"
        )
        puts "adding 'edge_type_content' to the config of 'config/initializers/types.rb'"
      end

      if destination_content.exclude?(node_type_content)
        destination_content.gsub(
          "Rails.application.config.to_prepare do\n  # Register AGE types",
          "Rails.application.config.to_prepare do\n  # Register AGE types\n  #{node_type_content}"
        )
        puts "adding 'node_type_content' to the config of 'config/initializers/types.rb'"
      end

      if destination_content != File.read(types_file_path)
        File.open(types_file_path, 'w') { |file| file.write(updated_content) }
        puts "config/initializers/types.rb is updated with AGE base type info."
      else
        puts "config/initializers/types.rb has AGE base types is already configired."
      end
    end
  end
end
