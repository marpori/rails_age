# config/initializers/types.rb

require 'apache_age/types/age_type_generator'
# USAGE (with edges or nodes) - ie:
# require_dependency 'nodes/company'
# ActiveModel::Type.register(
#   :company, ApacheAge::Types::AgeTypeGenerator.create_type_for(Nodes::Company)
# )

Rails.application.config.to_prepare do
  # Register AGE types
  require_dependency 'apache_age/node'
  ActiveModel::Type.register(
    :node, ApacheAge::Types::AgeTypeGenerator.create_type_for(ApacheAge::Node)
  )
  require_dependency 'apache_age/edge'
  ActiveModel::Type.register(
    :edge, ApacheAge::Types::AgeTypeGenerator.create_type_for(ApacheAge::Edge)
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
  require_dependency 'dog'
  ActiveModel::Type.register(
    :dog, ApacheAge::Types::AgeTypeGenerator.create_type_for(Dog)
  )
  require_dependency 'animals/cat'
  ActiveModel::Type.register(
    :animals_cat, ApacheAge::Types::AgeTypeGenerator.create_type_for(Animals::Cat)
  )
end