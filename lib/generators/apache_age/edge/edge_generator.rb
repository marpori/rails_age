# lib/generators/apache_age/edge/edge_generator.rb
require 'rails/generators'
require 'rails/generators/named_base'

require_relative '../generator_entity_helpers'
# TODO: get generators to work with custom types!
# require_relative "#{Rails.root}/config/initializers/types"

module ApacheAge
  class EdgeGenerator < Rails::Generators::NamedBase
    include ApacheAge::GeneratorEntityHelpers

    desc "Generates edge (model) with attributes."

    source_root File.expand_path('templates', __dir__)
    argument :attributes, type: :array, default: [], banner: "field:type field:type"

    def perform_task
      age_type = 'edge'
      Rails.application.eager_load! # Ensure all initializers and dependencies are loaded
      behavior == :invoke ? generate_age_entity(age_type) : destroy_age_entity(age_type)
    end

    private

    # different than node_generator.rb
    def unique_edge_attributes = unique_attributes + [:start_node, :end_node]
  end
end
