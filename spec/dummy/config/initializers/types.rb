# config/initializers/types.rb

require 'apache_age/types/age_type_generator'
# USAGE (with edges or nodes) - ie:
# require_dependency 'nodes/company'
# ActiveModel::Type.register(
#   :company, ApacheAge::Types::AgeTypeGenerator.create_type_for(Nodes::Company)
# )

Rails.application.config.to_prepare do
  # Register AGE types
  require_dependency 'apache_age/entities/vertex'
  ActiveModel::Type.register(
    :vertex, ApacheAge::Types::AgeTypeGenerator.create_type_for(ApacheAge::Entities::Vertex)
  )
  require_dependency 'apache_age/entities/edge'
  ActiveModel::Type.register(
    :edge, ApacheAge::Types::AgeTypeGenerator.create_type_for(ApacheAge::Entities::Edge)
  )

  # Register the custom types
  require_dependency 'nodes/company'
  ActiveModel::Type.register(
    :company, ApacheAge::Types::AgeTypeGenerator.create_type_for(Nodes::Company)
  )
  require_dependency 'nodes/person'
  ActiveModel::Type.register(
    :person, ApacheAge::Types::AgeTypeGenerator.create_type_for(Nodes::Person)
  )
end