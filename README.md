# RailsAge

Apache Age integration within a Rails application.

Inspired by: https://github.com/apache/age/issues/370

## Quick Start - Essentials

### Overview

This Gem uses 3 Major Concepts:

1. **Nodes** (Vertices) - usually nouns
2. **Edges** (Relationships) - usually verbs (or relational adjectives)
3. **Paths** (connections between nodes - heavy dependend on the `match` feature in cypher)

In this mini example we have the Flintstone Family Tree.
- Person (Node) - has attributes: first_name, last_name, gender
- Pet (Node) - has attributes: name, gender, species
- HasChild (Edge) - has attributes: guardian_role
- HasSibling (Edge) - has attributes: relation
- HasSpouse (Edge) - has attributes: spousal_role
- HasJob (Edge) - has attributes: employee_role

Paths are how you build the `network` of nodes and edges.


### Generators - simplify usage and rails integration

we have an installers and generators (we handle namespacing fully)

RailsAge generators (and generally support standard Rails datatypes) - not all AGE datatypes are supported (yet)

This includes:
  * string
  * integer
  * decimal
  * date
  * datetime
  * boolean

AGE supports (but not RailsAge):
  * array
  * hash
  * json

**Installers**

```bash
rails generate apache_age:install

# optional, but handy, it prevents `bin/rails db:migrate` from breaking the schema file,
rails generate apache_age:override_db_migrate
```

**NODES**

```bash
rails generate apache_age:scaffold_node Company company_name
rails generate apache_age:scaffold_node Person first_name last_name
```

**EDGES**

```bash
rails generate apache_age:scaffold_edge HasChild guardian_role
rails generate apache_age:scaffold_edge HasJob employee_role start_date:date
rails generate apache_age:scaffold_edge HasSibling start_relation
rails generate apache_age:scaffold_edge HasSpouse spousal_role
```


### INSTALL APACHE AGE

[Install Apache Age](https://age.apache.org/getstarted/quickstart)

**Quick Docker Install**

```bash
# pull the docker image
docker pull apache/age

# Create AGE docker container
docker run \
  --name age  \
  -p 5455:5432 \
  -e POSTGRES_USER=postgresUser \
  -e POSTGRES_PASSWORD=postgresPW \
  -e POSTGRES_DB=postgresDB \
  -d \
  apache/age

# enter the container and connect to the database (and test it)
docker exec -it age psql -d postgresDB -U postgresUser

# For every connection of AGE you start, you will need to load the AGE extension.
CREATE EXTENSION age;
LOAD 'age';
SET search_path = ag_catalog, "$user", public;
```


### RAILS PROJECT (Flintstone Family)

**NOTE:** you must be using Postgres as your database!

Apache Age requires using Postgres (`-d postgresql`)!

```bash
# SETUP A RAILS PROJECT (Flintstone Family Tree)
rails new stone_age -T -d postgresql
cd stone_age
git commit -m "initail commit"

# if using the default dockerized AGE PostgreSQL server then add the following to your `config/database.yml`
# BE SURE TO MATCH THE USERNAME AND PASSWORD TO WHAT YOU SET IN THE DOCKER RUN COMMAND!
host: localhost
port: 5455
username: postgresUser
password: postgresPW

# create the database
rails db:create

# add the rails_age gem to your Gemfile
bundle add rails_age

# download the rails_age gem
bundle install

# configure the Apache AGE gem (ignore the OID warnings)
bin/rails apache_age:install
# if you get the error: `PG::FeatureNotSupported: ERROR:  extension "age" is not available`
# then you have not installed the AGE code (in PostgreSQL) follow this instrcutions at:
# https://github.com/apache/age?tab=readme-ov-file#installation

# optional: prevents `bin/rails db:migrate` from modifying the schema file,
bin/rails apache_age:override_db_migrate
bin/rails db:migrate

# create nodes
bin/rails generate apache_age:scaffold_node Company company_name industry
bin/rails generate apache_age:scaffold_node Person first_name last_name gender
bin/rails generate apache_age:scaffold_node Pet name gender species
# adjust the validations in the nodes files

# create edges (relationships)
bin/rails generate apache_age:scaffold_edge HasChild guardian_role:string
bin/rails generate apache_age:scaffold_edge HasSibling relation:string
bin/rails generate apache_age:scaffold_edge HasSpouse spousal_role:string
bin/rails generate apache_age:scaffold_edge HasJob employee_role:string

# adjust the edge validations and start_node and end_node types: ie: thefore
# `HasChild` edge should add the model type following start_node and end_node
# in this case: `:person`
# app/edges/has_child.rb
class HasChild
  include ApacheAge::Entities::Edge

  attribute :guardian_role, :string
  attribute :start_node, :person
  attribute :end_node, :person
end

# seed file uses `db/seed.rb` (seed provides NO pets)
bin/rails db:seed

# list noutes
bin/rails routes

# start server `bin/rails s`
# or more likely when using JS:
bin/start

# visit the routes in your browser - you should have a basic but working AGE app - that can do both AGE (Graph) and normal Rails activities
```



## Queries

Mostly mimic **ActiveRecord** queries - if the class is an AGE based object (ie: a node or edge) then the queries are rewritten into AGE queries before being executed.  Age queries also automatically unwrap the results turning them into the appropriate Ruby class (node or edge).

1. `.all`
2. `.first`
2. `.save`
2. `.update`
2. `.destroy`
2. `.destroy_all` (not implemented)
2. `.update_attributes`
2. `.find(id)`
2. `.exists?` (not implemented)
3. `.find_by(first_name: 'Zeke', last_name: 'Flintstone')`
3. `.where(first_name: 'Zeke', last_name: 'Flintstone')`
4. `.order(last_name: :desc, first_name: :asc)`
5. `.limit(3)` (returns the first 3 records)
6. `.to_sql` (returns the SQL query)
7. `.cypher` (primarily for path queries - _builds a specialized cypher query for efficetly doing path queries - building efficient `match` statements_)

### Node Queries

```ruby
Dog.all
Dog.where(name: 'Pema')

Person.all
Person.where(first_name: 'Zeke', last_name: 'Flintstone')

ApacheAge::Node.all
# untested applying a where on nodes of different types, but should work
ApacheAge::Node.where(first_name: 'Zeke', last_name: 'Flintstone')
```

### Edge Queries

```ruby
HasChild.all
HasChild.where(guardian_role: 'father')

HasJob.all
HasJob.where(employee_role: 'doctor')

ApacheAge::Edge.all
# untested applying a where on edges of different types, but should work
ApacheAge::Edge.where(employee_role: 'doctor')
```

### Path Queries

the connections between nodes and edges - this is important for advanced queries and relies heavily on the `match` feature in cypher (using match is faster for large datasets than using where to filter the data!)

A Path Query must have the `cypher` method called on the `Path` class.  
```ruby
Path.cypher(path_edge: HasChild, path_length: "1..5", path_properties: {guardian_role: 'father'}, start_node_filter: {first_name: 'Zeke'}, end_node_filter: {last_name: 'Flintstone'})
    .order(start_node: :last_name)
    .limit(3)
```
**NOTE**: you can order on the start_node and end_node attributes, BUT NOT ON THE EDGE ATTRIBUTES (age limitation), even though you can filter on the edge attributes!

A path query returns an array of paths (each path is an array of nodes and edges)
```ruby
[
  [betty (node), bettys_son (edge), bamm_bamm (node)],
  [betty (node), bettys_son (edge), bamm_bamm (node), bamm_bamms_son (edge), chip (node)]
]
```

To make a path more readable for debugging you can use the `to_rich_h` method

```ruby
# hash metadata (rich hash) and is data is in properties (closer to the DB format)
path_query.all.first.to_rich_h
path_query.all.map(&:to_rich_h)
# default to_h works on paths too with (flat data hash of record):
path_query.all.first.map(&:to_h)
path_query.all.map { |p| p.map(&:to_h) }
```

SQL Comparison with `match` and with `where` (in small datasets you won't see efficiency differences, but for large datasets `match` is much more efficient)
```ruby
# EFFICIENT - the data is filtered in one step during the data traversal
Path.cypher(path_edge: HasChild, path_length: "1..5", path_properties: {guardian_role: 'father'}, start_node_filter: {first_name: 'Zeke'}, end_node_filter: {last_name: 'Flintstone'})
    .order(start_node: {last_name: :asc}, length: :desc)
    .limit(3).to_sql
# SELECT *
# FROM cypher('age_schema', $$
#   MATCH path = (start_node {first_name: 'Zeke'})-[HasChild*1..5 {guardian_role: 'father'}]->(end_node {last_name: 'Flintstone'})
#   RETURN path
#   ORDER BY start_node.last_name ASC, length(path) DESC
#   LIMIT 3
# $$) AS (path agtype);


# INEFFICIENT - because where is done after the match traversal (two steps through the data)
Path.cypher(path_edge: HasChild, path_length: "1..5", path_properties: {guardian_role: 'father'})
    .where(start_node: {first_name: 'Zeke'})
    .where('end_node.last_name =~ ?', 'Flintstone')
    .order(start_node: {last_name: :asc}, length: :desc)
    .limit(3).to_sql
# SELECT *
# FROM cypher('age_schema', $$
#   MATCH path = (start_node)-[HasChild*1..5 {guardian_role: 'father'}]->(end_node)
#   WHERE start_node.first_name = 'Zeke' AND end_node.last_name =~ 'Flintstone'
#   RETURN path
#   ORDER BY start_node.last_name ASC, length(path) DESC
#   LIMIT 3
# $$) AS (path agtype);
```

## Console Usage

**NOTE**
using rails attributes complicates the default output of the model, thus it is strong recommended to use the `to_rich_h` method to display the results with meta_data so the class is known (or `to_h` - just the essential data).

```ruby
dino = Pet.create(name: 'Dino', gender: 'male', species: 'dinosaur')
dino.to_rich_h

# find a person
fred = Person.find_by(first_name: 'Fred', last_name: 'Flintstone')
fred.to_rich_h

pebbles = Person.find_by(first_name: 'Pebbles')
pebbles.to_rich_h

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

# Path Queries - returns all elements that match a given path to find specific sets of relationships
path = Path.cypher(path_edge: HasChild, path_length: "1..5", path_properties: {guardian_role: 'father'}, start_node_filter: {first_name: 'Zeke'}, end_node_filter: {last_name: 'Flintstone'})
    .order(start_node: {last_name: :asc}, length: :desc)
    .limit(3)

# should redo the example using: path.all.map(&:to_rich_h) to make more readable
path.all.map { |p| p.map(&:to_h) }
>[[{:id=>844424930131969, :first_name=>"Zeke", :last_name=>"Flintstone", :gender=>"female"},
  {:id=>1407374883553281,
   :end_id=>844424930131971,
   :start_id=>844424930131969,
   :guardian_role=>"mother",
   :end_node=>{:id=>844424930131971, :first_name=>"Rockbottom", :last_name=>"Flintstone", :gender=>"male"},
   :start_node=>{:id=>844424930131969, :first_name=>"Zeke", :last_name=>"Flintstone", :gender=>"female"}},
  {:id=>844424930131971, :first_name=>"Rockbottom", :last_name=>"Flintstone", :gender=>"male"}],
 [{:id=>844424930131969, :first_name=>"Zeke", :last_name=>"Flintstone", :gender=>"female"},
  {:id=>1407374883553281,
   :end_id=>844424930131971,
   :start_id=>844424930131969,
   :guardian_role=>"mother",
   :end_node=>{:id=>844424930131971, :first_name=>"Rockbottom", :last_name=>"Flintstone", :gender=>"male"},
   :start_node=>{:id=>844424930131969, :first_name=>"Zeke", :last_name=>"Flintstone", :gender=>"female"}},
  {:id=>844424930131971, :first_name=>"Rockbottom", :last_name=>"Flintstone", :gender=>"male"},
  {:id=>1407374883553284,
   :end_id=>844424930131975,
   :start_id=>844424930131971,
   :guardian_role=>"father",
   :end_node=>{:id=>844424930131975, :first_name=>"Giggles", :last_name=>"Flintstone", :gender=>"male"},
   :start_node=>{:id=>844424930131971, :first_name=>"Rockbottom", :last_name=>"Flintstone", :gender=>"male"}},
  {:id=>844424930131975, :first_name=>"Giggles", :last_name=>"Flintstone", :gender=>"male"}]]

raw_pg_results = Person.where(last_name: 'Flintstone').order(:first_name).limit(4).execute
=> #<PG::Result:0x000000012255f348 status=PGRES_TUPLES_OK ntuples=4 nfields=1 cmd_tuples=4>
raw_pg_results.values
> [["{\"id\": 844424930131974, \"label\": \"Person\", \"properties\": {\"gender\": \"male\", \"last_name\": \"Flintstone\", \"first_name\": \"Ed\"}}::vertex"],
>  ["{\"id\": 844424930131976, \"label\": \"Person\", \"properties\": {\"gender\": \"female\", \"last_name\": \"Flintstone\", \"first_name\": \"Edna\"}}::vertex"],
>  ["{\"id\": 844424930131986, \"label\": \"Person\", \"properties\": {\"gender\": \"male\", \"last_name\": \"Flintstone\", \"first_name\": \"Fred\"}}::vertex"],
>  ["{\"id\": 844424930131975, \"label\": \"Person\", \"properties\": {\"gender\": \"male\", \"last_name\": \"Flintstone\", \"first_name\": \"Giggles\"}}::vertex"]]
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

### Experiment directly with AGE

Play with AGE/cypher directly (if desired) - see: https://age.apache.org/getstarted/quickstart

To create a graph, use the create_graph function located in the ag_catalog namespace.

enter postgres via:
- `psql -h localhost -p 5455 -U docker_username`
or
- `docker exec -it age psql -d postgresDB -U postgresUser`

then in psql:
```sql
-- For every connection of AGE you start, you will need to load the AGE extension.
CREATE EXTENSION age;
LOAD 'age';
SET search_path = ag_catalog, "$user", public;

SELECT create_graph('graph_name');

# To create a single vertex with label and properties, use the CREATE clause.
SELECT *
FROM cypher('graph_name', $$
    CREATE (:label {property:"Node A"})
$$) as (v agtype);

# create a second vertex (node)
SELECT *
FROM cypher('graph_name', $$
    CREATE (:label {property:"Node B"})
$$) as (v agtype);

# To create an edge between the nodes and set its properties:
SELECT *
FROM cypher('graph_name', $$
    MATCH (a:label), (b:label)
    WHERE a.property = 'Node A' AND b.property = 'Node B'
    CREATE (a)-[e:RELTYPE {property:a.property + '<->' + b.property}]->(b)
    RETURN e
$$) as (e agtype);

# Query the connected nodes:
SELECT * from cypher('graph_name', $$
        MATCH (V)-[R]-(V2)
        RETURN V,R,V2
$$) as (V agtype, R agtype, V2 agtype);

\q
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
