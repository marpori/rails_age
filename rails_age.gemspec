require_relative 'lib/rails_age/version'

Gem::Specification.new do |spec|
  spec.name        = 'rails_age'
  spec.version     = RailsAge::VERSION
  spec.authors     = ['Bill Tihen']
  spec.email       = ['btihen@gmail.com']
  spec.homepage    = 'https://github.com/marpori/rails_age'
  spec.summary     = 'Apache AGE plugin for Rails 7.x'
  spec.description = 'This plugin integrates Apache AGE for PostgreSQL with Rails 7.x, providing tools and helpers for working with graph databases within a Rails application.'

  spec.license     = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host''
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = "#{spec.homepage}/blob/main"
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", 'MIT-LICENSE', 'Rakefile', 'README.md', 'CHANGELOG.md']
  end

  spec.required_ruby_version = '>= 3.2'
  spec.add_dependency 'rails', '>= 7.0', '< 9.0'
  # json/common.rb requires 'ostruct' - this prevents a warning until json gem is updated
  spec.add_dependency 'ostruct'

  spec.add_development_dependency 'rspec-rails', '~> 6.0'
  spec.add_development_dependency 'capybara', '~> 3.4'
  spec.add_development_dependency 'selenium-webdriver'
end
