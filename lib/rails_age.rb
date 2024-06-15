require 'rails_age/version'
require 'rails_age/engine'

module RailsAge
  # Your code goes here...
end

module ApacheAge
  require 'apache_age/entities/class_methods'
  require 'apache_age/entities/common_methods'
  require 'apache_age/entities/edge'
  require 'apache_age/entities/entity'
  require 'apache_age/entities/vertex'
  require 'apache_age/validators/unique_edge'
  require 'apache_age/validators/unique_vertex'
  require 'apache_age/types/age_type_generator'
end
