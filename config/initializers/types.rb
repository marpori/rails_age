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
end
