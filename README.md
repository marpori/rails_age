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

setup (& Test) postgresql with AGE (using the docker version of AGE DB may be the easiest way to get started)
using the docker version of AGE DB, you can confirm psql AGE with the following commands:
```bash
psql -h localhost -p 5455 -U docker_username
> CREATE EXTENSION IF NOT EXISTS age;
> LOAD 'age';
> SET search_path = ag_catalog, "$user", public;
> SELECT create_graph('age_schema');
> \q
```

create a new Rails app (WITH POSTGRESQL!)
```bash
rails new age_demo -d postgresql
cd age_demo
git add .
git commit -m "Initial Rails App"
```
configure `config/database.yml` when using the docker version of AGE DB my config looks like:
```yaml
port: 5455
host: localhost
username: docker_username
password: dockerized_password
```

now you should be able to create the rails database:
```bash
rails db:create
rails db:migrate
git add .
git commit -m "Add Apache Age Postgres DB configured with Rails App"
```

install Apache Age (you can ignore the `unknown OID` warnings)
```bash
bundle add rails_age
bundle install
bin/rails apache_age:install
# optional: prevents `bin/rails db:migrate` from modifying the schema file,
# alternatively you can use: `bin/rails apache_age:migrate` to run safe migrations
bin/rails apache_age:override_db_migrate
git add .
git commit -m "Add & configure Apache Age within Rails"
```

make some nodes :string is the default type
```bash
rails generate apache_age:node Company company_name
rails generate apache_age:node Person first_name last_name
rails generate apache_age:node Pet pet_name:string age:integer
```
make some edges (`:vertex` is the default type) for start_node and end_node
```bash
# when start node and end node are not specified they are of type `:vertex`
# this is generally not recommended - exept when very generic relationships are needed
rails generate apache_age:edge HasJob employee_role begin_date:date

# # this is recommended - (but not yet working) add explicit start_node and end_node types manually
# rails generate apache_age:node HasPet start_node:person end_node:pet caretaker_role
```

**NOTE:** the default `rails db:migrate` inappropriately modifies the schema file. This installer patches the migration to prevent this (however this might break on rails updates, etc). **You can run `bin/rails apache_age:install` at any time to repair the schema file as needed.**

For now, if you are using `db/structure.sql` you will need to manually configure Apache Age (RailsAge) as described below.

### Rails Console Usage

```ruby
bin/rails c

fred = Person.new(first_name: 'Fredrick Jay', last_name: 'Flintstone')
fred.valid?
fred.save
fred.to_h # should have an ID

# fails because of a missing required field (Property)
incomplete = Person.new(first_name: 'Fredrick Jay')
incomplete.valid?
incomplete.errors
incomplete.to_h

# fails because of uniqueness constraints
jay = Person.create(first_name: 'Fredrick Jay', last_name: 'Flintstone')
jay.to_h
=> {:id=>nil, :first_name=>"Fredrick Jay", :last_name=>"Flintstone"}
jay.valid?
=> false
jay.errors
=> #<ActiveModel::Errors [#<ActiveModel::Error attribute=base, type=record not unique, options={}>, #<ActiveModel::Error attribute=first_name, type=property combination not unique, options={}>, #<ActiveModel::Error attribute=last_name, type=property combination not unique, options={}>]>
irb(main):008> jav.to_h
=> {:id=>nil, :first_name=>"Fredrick Jay", :last_name=>"Flintstone"}

# .create is a shortcut for .new and .save
quarry = Company.create(company_name: 'Bedrock Quarry')
quarry.to_h # should have an ID

# create an edge (no generator yet)
job = HasJob.create(start_node: fred, end_node: quarry, employee_role: 'Crane Operator')
job.to_h # should have an ID
```

## Manual Install, Config and Usage

see [Manuel Installation, Configuration and Usage](MANUAL_INSTALL.md)
