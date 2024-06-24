# lib/generators/apache_age/node/entity_generator.rb
require 'rails/generators'
require 'rails/generators/named_base'

require_relative '../generator_entity_helpers'

module ApacheAge
  class NodeGenerator < Rails::Generators::NamedBase
    include ApacheAge::GeneratorEntityHelpers

    desc "Generates node (model) with attributes."
    source_root File.expand_path('templates', __dir__)
    argument :attributes, type: :array, default: [], banner: "field:type field:type"
    class_option :skip_namespace, type: :boolean, default: true, desc: "Skip namespace 'rails_age' in generated files"

    def perform_task
      age_type = 'node'
      behavior == :invoke ? generate_age_entity(age_type) : destroy_age_entity(age_type)
    end
  end
end
