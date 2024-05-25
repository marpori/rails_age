require_relative "lib/rails_age/version"

Gem::Specification.new do |spec|
  spec.name        = "rails_age"
  spec.version     = RailsAge::VERSION
  spec.authors     = ["Bill Tihen"]
  spec.email       = ["btihen@gmail.com"]
  spec.homepage    = "https://github.com/marpori/rails_age"
  spec.summary     = "Apache AGE plugin for Rails 7.1"
  spec.description = spec.summary
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  end

  spec.add_dependency "rails", ">= 7.0.0"

  spec.add_development_dependency 'rspec-rails'
end
