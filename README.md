# RailsAge

Apache Age integration within a Rails application.

## Quick Start - Essentials

**NOTE:** you must be using Postgres as your database! Apache Age requires it.

```bash
bundle add rails_age
bundle install
bin/rails apache_age:install
# optional: prevents `bin/rails db:migrate` from modifying the schema file,
# bin/rails apache_age:override_db_migrate
git add .
git commit -m "Add & configure Apache Age within Rails"
```

## Generators

**NODES**

```bash
rails generate apache_age:scaffold_node Company company_name

rails generate apache_age:scaffold_node Person first_name last_name
```

**EDGES**

```bash
rails generate apache_age:scaffold_edge HasJob employee_role start_date:date
```

Ideally, edit the HasJob class so that `start_node` would use a type `:person` and the `end_node` uses at type `:company`

ie:
```ruby
# app/edges/has_job.rb
class HasJob
  include ApacheAge::Entities::Edge

  attribute :employee_role, :string
  attribute :start_node, :person # instead of `:node`
  attribute :end_node, :company # instead of `:node`

  validates :employee_role, presence: true
  validate :validate_unique_edge

  private

  def validate_unique_edge
    ApacheAge::Validators::UniqueEdge
      .new(attributes: %i[employee_role start_node end_node])
      .validate(self)
  end
end
```

## Installation in Detail

using the installer, creates the migration to install age, runs the migration, and adjusts the schema file, and updates the `config/database.yml` file.

### Install Apache Age

see: [Apache AGE Installation](https://age.apache.org/age-manual/master/intro/setup.html#installation)
(The docker install is probably the easiest way to get started with a new application - for existing applications you may need to compile the extension from source.)

Verify your PostgreSQL AGE with the following commands:

```bash
$ psql -h localhost -p 5455 -U docker_username

> CREATE EXTENSION IF NOT EXISTS age;
> LOAD 'age';
> SET search_path = ag_catalog, "$user", public;
> SELECT create_graph('age_schema');
> \q
```

### Install and Configure Rails (if not done already)

AGE REQUIRES POSTGRESQL!

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

If both the Rails DB config and AGE DB are correctly configured, you should be able to run the following command without error:

```bash
rails db:create
rails db:migrate
git add .
git commit -m "Basic Rails Configuration"
```

### install Apache Age Plugin

NOTE: _ignore the `unknown OID` warnings_

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

### Optional Migration override (OPTIONAL)

run `bin/rails apache_age:override_db_migrate` to ensure that running `rails db:migrate` does not inappropriately modify the schema file.

However, if you are familiar with the schema file and git then you can safely ignore this step and manage the changes after a migration manually - only submitting changes directly related to the newest migration and not those related AGE.

**NOTE:**
* **You can run `bin/rails apache_age:config_schema` at any time to repair the schema file as needed.**
( **You can run `bin/rails apache_age:install` at any time to repair any AGE related config file**

If you are using `db/structure.sql` you will need to manually configure Apache Age (RailsAge).

### NODE Scaffold Generation

```bash
rails generate apache_age:scaffold_node Company company_name:string

# string is the default type (so it can be omitted)
rails generate apache_age:scaffold_node Person first_name last_name

# with a namespace
rails generate apache_age:scaffold_node Animals/Pet pet_name birthdate:date
```

### EDGE Scaffold Generation**

NOTE: the generator will only allow `:node` (default type) for start_node and end_node, however, it is strongly recommended to specify the start_node and end_node types manually. _Hopefully, I can find a way to get the generators to recognize and allow the usage of custom node types. Thus eventually, I hope: `rails generate apache_age:node HasPet start_node:person end_node:pet caretaker_role` will work._

```bash
rails generate apache_age:edge HasJob employee_role begin_date:date
```

_edge scaffold is coming soon._

```bash
# without a namespace
rails generate apache_age:scaffold_edge HasPet caretaker_role

# with a namespace
rails generate apache_age:scaffold_edge People/HasSpouse spousal_role
```

### AGE Usage within Rails Console

see [AGE Usage within Rails Console](AGE_CONSOLE_USAGE.md)

## Manual Install, Config and Usage

see [Manuel Installation, Configuration and Usage](MANUAL_INSTALL.md)
