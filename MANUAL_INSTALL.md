## Getting Started

**NOTE:** you must be using **Postgres** as your database! Apache Age requires it.

Add this line to your application's Gemfile:

```bash
rails new age_demo -d postgresql
cd age_demo
git add .
git commit -m "Initial Rails Commit"
```


## Manual AGE Installation
add the following to your `Gemfile`:

```ruby
gem 'rails_age'
```

and install it with:
```bash
$ bundle install
```
### Add Apache Age DB extension

```bash
create a migration to add the Apache Age extension to your database
```bash
$ bin/rails g migration AddApacheAge
```
copy the contents of https://github.com/marpori/rails_age/blob/main/db/migrate/20240521062349_add_apache_age.rb
```ruby
class AddApacheAge < ActiveRecord::Migration[7.1]
  def up
    # Allow age extension
    execute('CREATE EXTENSION IF NOT EXISTS age;')

    # Load the age code
    execute("LOAD 'age';")

    # Load the ag_catalog into the search path
    execute('SET search_path = ag_catalog, "$user", public;')

    # Create age_schema graph if it doesn't exist
    execute("SELECT create_graph('age_schema');")
  end

  def down
    execute <<-SQL
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1
          FROM pg_constraint
          WHERE conname = 'fk_graph_oid'
        ) THEN
          ALTER TABLE ag_catalog.ag_label
          DROP CONSTRAINT fk_graph_oid;
        END IF;
      END $$;
    SQL

    execute("SELECT drop_graph('age_schema', true);")
    execute('DROP SCHEMA IF EXISTS ag_catalog CASCADE;')
    execute('DROP EXTENSION IF EXISTS age;')
  end
end
```
into your new migration file

then run the migration
```bash
$ bin/rails db:migrate
```

### Fix the schema.rb file

Rails migrate will mangle the schema `db/schema.rb` file.  You need to remove the lines that look like:
```ruby
ActiveRecord::Schema[7.1].define(version: 2024_05_21_062349) do
  create_schema "ag_catalog"
  create_schema "age_schema"

  # These are extensions that must be enabled in order to support this database
  enable_extension "age"
  enable_extension "plpgsql"

  # Could not dump table "_ag_label_edge" because of following StandardError
  #   Unknown type 'graphid' for column 'id'

  # Could not dump table "_ag_label_vertex" because of following StandardError
  #   Unknown type 'graphid' for column 'id'

  # Could not dump table "ag_graph" because of following StandardError
  #   Unknown type 'regnamespace' for column 'namespace'

  # Could not dump table "ag_label" because of following StandardError
  #   Unknown type 'regclass' for column 'relation'

  add_foreign_key "ag_label", "ag_graph", column: "graph", primary_key: "graphid", name: "fk_graph_oid"

  # other migrations
  # ...
end
```

and replace them with the following lines:
```ruby
ActiveRecord::Schema[7.1].define(version: 2024_05_21_062349) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  # Allow age extension
  execute('CREATE EXTENSION IF NOT EXISTS age;')

  # Load the age code
  execute("LOAD 'age';")

  # Load the ag_catalog into the search path
  execute('SET search_path = ag_catalog, "$user", public;')

  # Create age_schema graph if it doesn't exist
  execute("SELECT create_graph('age_schema');")

  # other migrations
  # ...
end
```

NOTE: if using `db/structure.sql` use:
```sql
-- These are extensions that must be enabled in order to support this database
CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA public;

-- Allow age extension (if not already enabled), this builds the age_catalog schema
CREATE EXTENSION IF NOT EXISTS age;

-- Load the age module
LOAD 'age';

-- Load the ag_catalog into the search path
SET search_path = ag_catalog, "$user", public;

-- Create age_schema graph if it doesn't exist
SELECT create_graph('age_schema');

# other migrations
# ...

INSERT INTO "schema_migrations" (version) VALUES
('20110315075839'),
--- ...
('20240521062349');
```

### Add AGE types

configuring types:
```ruby
# config/initializers/types.rb

require 'apache_age/types/age_type_generator'

Rails.application.config.to_prepare do

  # Register the AGE types
  require_dependency 'apache_age/node'
  ActiveModel::Type.register(
    :node, ApacheAge::Types::AgeTypeGenerator.create_type_for(ApacheAge::Node)
  )
  require_dependency 'apache_age/edge'
  ActiveModel::Type.register(
    :edge, ApacheAge::Types::AgeTypeGenerator.create_type_for(ApacheAge::Edge)
  )
end
```

### Nodes

Create a directory for your nodes:
```bash
$ mkdir app/nodes
```

```ruby
# app/nodes/company.rb
class Company
  include ApacheAge::Entities::Vertex

  attribute :company_name, :string

  validates :company_name, presence: true
  validates_with(
    ApacheAge::Validators::UniqueVertex,
    attributes: [:company_name]
  )
end
```

```ruby
# app/nodes/person.rb
class Person
  include ApacheAge::Entities::Vertex

  attribute :first_name, :string, default: nil
  attribute :last_name, :string, default: nil
  attribute :given_name, :string, default: nil
  attribute :nick_name, :string, default: nil

  validates :first_name, :last_name, :given_name, :nick_name,
            presence: true

  def initialize(**attributes)
    super
    # use unless present? since attributes when empty sets to "" by default
    self.nick_name = first_name unless nick_name.present?
    self.given_name = last_name unless given_name.present?
  end
end
```

### Edges

```ruby
# app/graphs/edges/has_job.rb
module Edges
  class HasJob
    include ApacheAge::Entities::Edge

    attribute :employee_role, :string
    attribute :start_node, :person
    attribute :end_node, :company

    validates :employee_role, presence: true
    validate :validate_unique
    # or with a one-liner
    # validates_with(
    #   ApacheAge::Validators::UniqueEdge,
    #   attributes: %i[employee_role start_node end_node]
    # )

    private

    def validate_unique
      ApacheAge::Validators::UniqueEdge
        .new(attributes: %i[employee_role start_node end_node])
        .validate(self)
    end
  end
end
```

### Rails Console Usage

```ruby
fred = Nodes::Person.create(first_name: 'Fredrick Jay', nick_name: 'Fred', last_name: 'Flintstone', gender: 'male')
fred.to_h

quarry = Nodes::Company.create(company_name: 'Bedrock Quarry')
quarry.to_h

job = Edges::HasJob.create(start_node: fred, end_node: quarry, employee_role: 'Crane Operator')
job.to_h
```

### Update Routes

```ruby
Rails.application.routes.draw do
  # mount is not needed with the engine
  # mount RailsAge::Engine => "/rails_age"

  # defines the route for the people controller
  resources :people

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  root 'people#index'
end
```

### Types (Optional)

```ruby
# spec/dummy/config/initializers/types.rb
require 'apache_age/types/age_type_generator'

Rails.application.config.to_prepare do
  # Ensure the files are loaded
  require_dependency 'nodes/company'
  require_dependency 'nodes/person'

  # Register the custom types
  ActiveModel::Type.register(
    :company, ApacheAge::Types::AgeTypeGenerator.create_type_for(Nodes::Company)
  )
  ActiveModel::Type.register(
    :person, ApacheAge::Types::AgeTypeGenerator.create_type_for(Nodes::Person)
  )
end
```

### Controller Usage

```ruby
# app/controllers/people_controller.rb
class PeopleController < ApplicationController
  before_action :set_person, only: %i[show edit update destroy]

  # GET /people or /people.json
  def index
    @people = Nodes::Person.all
  end

  # GET /people/1 or /people/1.json
  def show; end

  # GET /people/new
  def new
    @person = Nodes::Person.new
  end

  # GET /people/1/edit
  def edit; end

  # POST /people or /people.json
  def create
    @person = Nodes::Person.new(**person_params)
    respond_to do |format|
      if @person.save
        format.html { redirect_to person_url(@person), notice: 'Person was successfully created.' }
        format.json { render :show, status: :created, location: @person }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /people/1 or /people/1.json
  def update
    respond_to do |format|
      if @person.update(**person_params)
        format.html { redirect_to person_url(@person), notice: 'Person was successfully updated.' }
        format.json { render :show, status: :ok, location: @person }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /people/1 or /people/1.json
  def destroy
    @person.destroy!

    respond_to do |format|
      format.html { redirect_to people_url, notice: 'Person was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_person
    @person = Nodes::Person.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def person_params
    # params.fetch(:person, {})
    params.require(:nodes_person).permit(:first_name, :last_name, :nick_name, :given_name, :gender)
  end
end
```

### Views

```erb

```
