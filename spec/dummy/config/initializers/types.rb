# spec/dummy/config/initializers/types.rb
require 'apache_age/types/age_type_generator'

Rails.application.config.to_prepare do
  # Ensure the files are loaded
  # require_dependency 'apache_age/entities/vertex'
  require_dependency 'nodes/company'
  require_dependency 'nodes/person'

  # Register the custom types
  # ActiveModel::Type.register(:vertex, ApacheAge::Types::AgeTypeGenerator.create_type_for(ApacheAge::Entities::Vertex))
  ActiveModel::Type.register(:company, ApacheAge::Types::AgeTypeGenerator.create_type_for(Nodes::Company))
  ActiveModel::Type.register(:person, ApacheAge::Types::AgeTypeGenerator.create_type_for(Nodes::Person))
end
