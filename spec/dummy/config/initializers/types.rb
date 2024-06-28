# config/initializers/types.rb

require 'apache_age/types/factory'
# USAGE (with edges or nodes) - ie:
# require_dependency 'company'
# ActiveModel::Type.register(
#   :company, ApacheAge::Types::Factory.type_for(Company)
# )

Rails.application.config.to_prepare do
  # Register AGE types
  require_dependency 'apache_age/node'
  ActiveModel::Type.register(
    :node, ApacheAge::Types::Factory.type_for(ApacheAge::Node)
  )
  require_dependency 'apache_age/edge'
  ActiveModel::Type.register(
    :edge, ApacheAge::Types::Factory.type_for(ApacheAge::Edge)
  )

  # Register the custom types
  require_dependency 'nodes/company'
  ActiveModel::Type.register(
    :company, ApacheAge::Types::Factory.type_for(Nodes::Company)
  )
  require_dependency 'nodes/person'
  ActiveModel::Type.register(
    :person, ApacheAge::Types::Factory.type_for(Nodes::Person)
  )
  require_dependency 'dog'
  ActiveModel::Type.register(
    :dog, ApacheAge::Types::Factory.type_for(Dog)
  )
  require_dependency 'animals/cat'
  ActiveModel::Type.register(
    :animals_cat, ApacheAge::Types::Factory.type_for(Animals::Cat)
  )
  require_dependency 'people/has_cat'
  ActiveModel::Type.register(
    :people_has_cat, ApacheAge::Types::Factory.type_for(People::HasCat)
  )
  require_dependency 'has_dog'
  ActiveModel::Type.register(
    :has_dog, ApacheAge::Types::Factory.type_for(HasDog)
  )
  require_dependency 'character'
  ActiveModel::Type.register(
    :character, ApacheAge::Types::Factory.type_for(Character)
  )
  require_dependency 'flintstones/character'
  ActiveModel::Type.register(
    :flintstones_character, ApacheAge::Types::Factory.type_for(Flintstones::Character)
  )
end
