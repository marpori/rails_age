require "rails_age/version"
require "rails_age/engine"

module RailsAge
  # Your code goes here...
end

module ApacheAge
  require "apache_age/class_methods"
  require "apache_age/common_methods"
  require "apache_age/edge"
  require "apache_age/entity"
  require "apache_age/vertex"
end
