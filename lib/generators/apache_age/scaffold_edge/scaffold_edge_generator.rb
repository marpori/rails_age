# lib/generators/apache_age/scaffold_edge/scaffold_edge_generator.rb

require 'rails/generators'
require 'rails/generators/named_base'
require 'rails/generators/resource_helpers'

module ApacheAge
  class ScaffoldEdgeGenerator < Rails::Generators::NamedBase
    include Rails::Generators::ResourceHelpers

    desc "Generates an edge, and its controller and views with the given attributes."

    source_root File.expand_path("templates", __dir__)

    argument :attributes, type: :array, default: [], banner: "field:type field:type"

    def create_model_file
      invoke 'apache_age:edge', [name] + attributes.collect { |attr| "#{attr.name}:#{attr.type}" }
    end

    def create_controller_files
      template(
        "controller.rb.tt",
        File.join(Rails.root, "app/controllers", controller_class_path, "#{controller_file_name}_controller.rb")
      )
    end

    def create_route
      route_content = route_text(class_path, file_name)
      inject_into_file(
        File.join(Rails.root, 'config', 'routes.rb'), "\n#{route_content}",
        after: "Rails.application.routes.draw do"
      )
    end

    def copy_view_files
      available_views.each do |view|
        view_name = view == 'partial' ? "_#{singular_table_name}" : view
        filename = filename_with_extensions(view_name)
        template(
          "views/#{view}.html.erb.tt",
          File.join(Rails.root, "app/views", controller_file_path, filename)
        )
      end
    end

    private

    def available_views
      %w[index edit show new partial _form]
    end

    def filename_with_extensions(view)
      [view, :html, :erb].compact.join('.')
    end

    def route_text(class_path, file_name)
      return "  resources :#{file_name.pluralize}" if class_path.empty?

<<-RUBY
  namespace :#{class_path.join(':')} do
    resources :#{file_name.pluralize}
  end
RUBY
    end
  end
end
