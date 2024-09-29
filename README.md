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

Ideally, edit the HasJob class so that `start_node` would use a type `:person` and the `end_node` uses at type `:company` - this is not yet supported by the generator, but easy to do manually as shown below.  (The problem is that I havent been able to figure out how load all the rails types in the testing environment).

ie:
```ruby
# app/edges/has_job.rb
class HasJob
  include ApacheAge::Entities::Edge

  attribute :employee_role, :string
  attribute :start_node, :person
  attribute :end_node, :company

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

now you can test your nodes at:
```bash
http://localhost/people
# and
http://localhost/animals_pets
```

Note: Turbo seems to interfere with the default rails template's ability to show errors, this can easily be fixed by disabling turbo for forms that where turbo isn't needed by adding `data: { turbo: false }` to the form, ie:
```ruby
<%= form_with(model: animals_pet, data: { turbo: false }) do |form| %>
  ...
<% end %>
```

### EDGE Scaffold Generation**

```bash
# without a namespace
rails generate apache_age:scaffold_edge HasPet caretaker_role
rails generate apache_age:edge HasJob employee_role begin_date:date

# with a namespace
rails generate apache_age:scaffold_edge People/HasSpouce spousal_role
```

now you can test your edges at:
```bash
http://localhost/has_pets
http://localhost/has_jobs
# and
http://localhost/people/has_spouses
```

you can improve the view to only show the items you expect to be associated with the start- and end-node by changing the selects in the form from the generic form (finds all nodes):
```ruby
  <div>
    <%= form.label :end_node, style: "display: block" %>
    <%= form.collection_select(:end_id, ApacheAge::Node.all, :id, :display, prompt: 'Select an End-Node') %>
  </div>
```
to selecting a specific node expected (along with the desired 'name' in the list)
```ruby
  <div>
    <%= form.label :end_node, style: "display: block" %>
    <%= form.collection_select(:end_id, Company.all, :id, :company_name, prompt: 'Select a Company') %>
  </div>
```
so full form change for has_job could look like:
```ruby
# app/views/has_jobs/_form.html.erb
<%= form_with(model: has_job, url: form_url) do |form| %>
  <% if has_job.errors.any? %>
    <div style="color: red">
      <h2><%= pluralize(has_job.errors.count, "error") %> prohibited this has_job from being saved:</h2>

      <ul>
        <% has_job.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= form.label :employee_role, style: "display: block" %>
    <%= form.text_field :employee_role %>
  </div>

  <div>
    <%= form.label :start_node, style: "display: block" %>
    <%= form.collection_select(:start_id, Person.all, :id, :first_name, prompt: 'Select a person') %>
  </div>

  <div>
    <%= form.label :end_node, style: "display: block" %>
    <%= form.collection_select(:end_id, Company.all, :id, :company_name, prompt: 'Select a Company') %>
  </div>

  <div>
    <%= form.submit %>
  </div>
<% end %>
```

To make your code more robust (enforce that the appropriate node type is associate with the start- and end-nodes) you can adjust the edge definition by adding the node type to the `start_node` and `end_node` attributes.
from
```ruby
  attribute :start_node
  attribute :end_node
```
to:
```ruby
  attribute :start_node, :person
  attribute :end_node, :company
```
For example you can make the edge/has_pet.rb more robust by making the model look like:
```ruby
# app/edges/has_job.rb
class HasJob
  include ApacheAge::Entities::Edge

  attribute :employee_role, :string
  attribute :start_node, :person
  attribute :end_node, :company

  validates :employee_role, presence: true
  validate :validate_unique

  private

  def validate_unique
    ApacheAge::Validators::UniqueEdge
      .new(attributes: %i[employee_role start_node end_node])
      .validate(self)
  end
end
```

The generator will only allow `:node` (default type) since at the time of running the generator (at least within tests, the custom types are not known), eventually, I hope to find a way to fix that and allow:
`rails generate apache_age:node HasPet start_node:person end_node:pet caretaker_role`
but that doesn't work yet!

### AGE Rails Quick Example

```bash
rails new stone_age --database=postresql
cd stone_age

bundle add rails_age
bundle install
bin/rails apache_age:install
bin/rails apache_age:override_db_migrate
rails db:create
rails db:migrate
rails generate apache_age:scaffold_node Person first_name, last_name, gender
rails generate apache_age:scaffold_node Pet name gender species
rails generate apache_age:scaffold_edge HasChild role:string
rails generate apache_age:scaffold_edge HasSibling role:string
rails generate apache_age:scaffold_edge HasSpouse role:string

# seed file: [db/seed.rb](SEED.md)
rails db:seed

# Console Usage (seed doesn't provide any pets)
dino = Pet.create(name: 'Dino', gender: 'male', species: 'dinosaur')
dino.to_h

# find a person
fred = Person.find_by(first_name: 'Fred', last_name: 'Flintstone')
fred.to_h

pebbles = Person.find_by(first_name: 'Pebbles')
pebbles.to_h

# find an edge
father_relationship = HasChild.find_by(start_node: fred, end_node: pebbles)
father_relationship.to_h
> {:id=>1407374883553310,
 :end_id=>844424930131996,
 :start_id=>844424930131986,
 :role=>"father",
 :end_node=>{:id=>844424930131996, :last_name=>"Flintstone", :first_name=>"Pebbles", :gender=>"female"},
 :start_node=>{:id=>844424930131986, :last_name=>"Flintstone", :first_name=>"Fred", :gender=>"male"}}

# where - find multiple nodes
family = Person.where(last_name: 'Flintstone').order(:first_name).limit(4).all.puts family.map(&:to_h)

family
> [{:id=>844424930131974, :last_name=>"Flintstone", :first_name=>"Ed", :gender=>"male"},
>  {:id=>844424930131976, :last_name=>"Flintstone", :first_name=>"Edna", :gender=>"female"},
?  {:id=>844424930131986, :last_name=>"Flintstone", :first_name=>"Fred", :gender=>"male"},
>  {:id=>844424930131975, :last_name=>"Flintstone", :first_name=>"Giggles", :gender=>"male"}]

# all - unsorted
all_family = Person.where(last_name: 'Flintstone').all
puts all_family.map(&:to_h)
> {:id=>844424930131969, :last_name=>"Flintstone", :first_name=>"Zeke", :gender=>"female"}
> {:id=>844424930131970, :last_name=>"Flintstone", :first_name=>"Jed", :gender=>"male"}
> {:id=>844424930131971, :last_name=>"Flintstone", :first_name=>"Rockbottom", :gender=>"male"}
> {:id=>844424930131974, :last_name=>"Flintstone", :first_name=>"Ed", :gender=>"male"}
> {:id=>844424930131975, :last_name=>"Flintstone", :first_name=>"Giggles", :gender=>"male"}
> {:id=>844424930131976, :last_name=>"Flintstone", :first_name=>"Edna", :gender=>"female"}
> {:id=>844424930131986, :last_name=>"Flintstone", :first_name=>"Fred", :gender=>"male"}
> {:id=>844424930131987, :last_name=>"Flintstone", :first_name=>"Wilma", :gender=>"female"}
> {:id=>844424930131995, :last_name=>"Flintstone", :first_name=>"Stoney", :gender=>"male"}
> {:id=>844424930131996, :last_name=>"Flintstone", :first_name=>"Pebbles", :gender=>"female"}

# where - multiple edges (relations) - for now only edge attributes and start/end nodes can be queried
parental_relations = HasChild.where(end_node: pebbles)
puts parental_relations.map(&:to_h)
> {:id=>1407374883553310, :end_id=>844424930131996, :start_id=>844424930131986, :role=>"father", :end_node=>{:id=>844424930131996, :last_name=>"Flintstone", :first_name=>"Pebbles", :gender=>"female"}, :start_node=>{:id=>844424930131986, :last_name=>"Flintstone", :first_name=>"Fred", :gender=>"male"}}
> {:id=>1407374883553309, :end_id=>844424930131996, :start_id=>844424930131987, :role=>"mother", :end_node=>{:id=>844424930131996, :last_name=>"Flintstone", :first_name=>"Pebbles", :gender=>"female"}, :start_node=>{:id=>844424930131987, :last_name=>"Flintstone", :first_name=>"Wilma", :gender=>"female"}}


raw_pg_results = Person.where(last_name: 'Flintstone').order(:first_name).limit(4).execute
=> #<PG::Result:0x000000012255f348 status=PGRES_TUPLES_OK ntuples=4 nfields=1 cmd_tuples=4>
raw_pg_results.values
> [["{\"id\": 844424930131974, \"label\": \"Person\", \"properties\": {\"gender\": \"male\", \"last_name\": \"Flintstone\", \"first_name\": \"Ed\"}}::vertex"],
>  ["{\"id\": 844424930131976, \"label\": \"Person\", \"properties\": {\"gender\": \"female\", \"last_name\": \"Flintstone\", \"first_name\": \"Edna\"}}::vertex"],
>  ["{\"id\": 844424930131986, \"label\": \"Person\", \"properties\": {\"gender\": \"male\", \"last_name\": \"Flintstone\", \"first_name\": \"Fred\"}}::vertex"],
>  ["{\"id\": 844424930131975, \"label\": \"Person\", \"properties\": {\"gender\": \"male\", \"last_name\": \"Flintstone\", \"first_name\": \"Giggles\"}}::vertex"]]
```

### Age Cypher Queries

```ruby
flintstone_family =
  Person.where(last_name: 'Flintstone')
        .order(:first_name)
        .limit(4).all
        .map(&:to_h)

# generates the query
SELECT *
FROM cypher('age_schema', $$
    MATCH (find:Person)
    WHERE find.last_name = 'Flintstone'
    RETURN find
    ORDER BY find.first_name
    LIMIT 4
$$) as (Person agtype);

# and returns:
[{:id=>844424930131974, :last_name=>"Flintstone", :first_name=>"Ed", :gender=>"male"},
 {:id=>844424930131976, :last_name=>"Flintstone", :first_name=>"Edna", :gender=>"female"},
 {:id=>844424930131986, :last_name=>"Flintstone", :first_name=>"Fred", :gender=>"male"},
 {:id=>844424930131975, :last_name=>"Flintstone", :first_name=>"Giggles", :gender=>"male"}]
```

```ruby
query =
  Person.
    cypher('age_schema')
    .match("(a:Person), (b:Person)")
    .where("a.name = 'Node A'", "b.name = 'Node B'")
    .return("a.name", "b.name")
    .as("name_a agtype, name_b agtype")
    .execute
```

or more generally (soon - not yet tested nor santized):

```ruby
tihen =
  ApacheAge::Cypher
    .new('age_schema')
    .create("(person:Person {name: 'Tihen'})")
    .return('person')
    .as('Person agtype')
    .execute
```

see [AGE Cypher Queries](AGE_CYPHER_QUERIES.md)

### AGE Usage within Rails Console

see [AGE Usage within Rails Console](AGE_CONSOLE_USAGE.md)

## Manual Install, Config and Usage

see [Manuel Installation, Configuration and Usage](MANUAL_INSTALL.md)
