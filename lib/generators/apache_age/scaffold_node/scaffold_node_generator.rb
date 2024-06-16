# lib/generators/apache_age/scaffold_node/scaffold_node_generator.rb

require 'rails/generators'
require 'rails/generators/named_base'
require 'rails/generators/resource_helpers'

require_relative '../generator_entity_helpers'
require_relative '../generator_resource_helpers'

module ApacheAge
  class ScaffoldNodeGenerator < Rails::Generators::NamedBase
    include Rails::Generators::ResourceHelpers
    # include ApacheAge::GeneratorEntityHelpers
    # include ApacheAge::GeneratorResourceHelpers

    desc "Generates a node, and its controller and views with the given attributes."

    source_root File.expand_path("templates", __dir__)

    argument :attributes, type: :array, default: [], banner: "field:type field:type"

    def create_model_file
      invoke 'apache_age:node', [name] + attributes.collect { |attr| "#{attr.name}:#{attr.type}" }
    end

    def create_controller_files
      template(
        "node_controller.rb.tt",
        File.join("app/controllers", controller_class_path, "#{controller_file_name}_controller.rb")
      )
    end

    def create_route
      if class_path.empty?
        route "resources :#{file_name.pluralize}"
      else
        route nested_route(class_path, file_name)
      end
    end

    def copy_view_files
      available_views.each do |view|
        filename = filename_with_extensions(view)
        template "views/#{view}.html.erb.tt", File.join("app/views", controller_file_path, filename)
      end
    end

    private

    def available_views
      %w[index edit show new partial _form]
    end

    def filename_with_extensions(view)
      [view, :html, :erb].compact.join('.')
    end

    def nested_route(class_path, file_name)
      # "namespace :#{class_path.join(':')} do\n  resources :#{file_name.pluralize}\nend"
      <<~RUBY
      namespace :#{class_path.join(':')} do
        resources :#{file_name.pluralize}
      end
      RUBY
    end
  end
end
