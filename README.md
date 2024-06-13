# RailsAge

Simplify Apache Age usage within a Rails application.

## Installation

**NOTE:** you must be using Postgres as your database! Apache Age requires it.

Add this line to your application's Gemfile:

```ruby
gem "rails_age"
```

## Quick Start

using the installer, creates the migration to install age, runs the migration, and adjusts the schema file, and updates the `config/database.yml` file.

```bash
rails new age_demo -d postgresql
cd age_demo
git add .
git commit -m "Initial Rails App"
bundle add rails_age
bundle install
# since I am using the docker version of AGE DB, I need to add the following to my `config/database.yml` file:
port: 5455
host: localhost
username: docker_username
password: dockerized_password
# be sure you can use postgresql
rails db:create
rails db:migrate
# now install Apache Age (you can ignore the IOD warnings: `unknown OID`)
bin/rails apache_age:install
git add .
git commit -m "Add Apache Age to Rails"
# make some nodes *with properties) :string is the default type
rails generate apache_age:node Company company_name
rails generate apache_age:node Person first_name last_name
rails generate apache_age:node Pet pet_name:string age:integer
```

NOTE: it is important to commit the `db/schema.rb` to git because `rails db:migrate` inappropriately modifies the schema file (I haven't yet tested `db/structure.sql`).

**You can run `bin/rails apache_age:install` at any time to repair the schema file as needed.**

For now, if you are using `db/structure.sql` you will need to manually configure Apache Age (RailsAge) as described below.

### Rails Console Usage

```ruby
bin/rails c

fred = Person.new(first_name: 'Fredrick Jay', last_name: 'Flintstone')
fred.valid?
fred.save
fred.to_h

jay = Person.create(first_name: 'Fredrick Jay', last_name: 'Flintstone')
jay.to_h
=> {:id=>nil, :first_name=>"Fredrick Jay", :last_name=>"Flintstone"}
jay.valid?
=> false
jay.errors
=> #<ActiveModel::Errors [#<ActiveModel::Error attribute=base, type=attribute combination not unique, options={}>, #<ActiveModel::Error attribute=first_name, type=attribute combination not unique, options={}>, #<ActiveModel::Error attribute=last_name, type=attribute combination not unique, options={}>]>
irb(main):008> jav.to_h
=> {:id=>nil, :first_name=>"Fredrick Jay", :last_name=>"Flintstone"}

quarry = Company.create(company_name: 'Bedrock Quarry')
quarry.to_h

job = HasJob.create(start_node: fred, end_node: quarry, employee_role: 'Crane Operator')
job.to_h
```

## Manual Install, Config and Usage

see [Manuel Installation, Configuration and Usage](MANUAL_INSTALL.md)
