# lib/generators/apache_age/node/entity_generator.rb
require 'rails/generators'
require 'rails/generators/named_base'

require_relative '../generate_entity_methods'

module ApacheAge
  class NodeGenerator < Rails::Generators::NamedBase
    include ApacheAge::GenerateEntityMethods

    source_root File.expand_path('templates', __dir__)
    argument :attributes, type: :array, default: [], banner: "field:type field:type"

    def perform_task
      age_type = 'node'
      behavior == :invoke ? generate_age_entity(age_type) : destroy_age_entity(age_type)
    end
  end
end
