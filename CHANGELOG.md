# Change Log

## VERSION 0.7.0 - 2025-06-01

**Age Path** - nodes and edges combined

- query paths (control path, length/depth and filtering using `match`)
  - code: `Path.cypher(path_edge: HasChild, path_length: "1..5", path_properties: {guardian_role: 'father'}, start_node_filter: {first_name: 'Zeke'}, end_node_filter: {last_name: 'Flintstone'})`
  - code.to_sql: `SELECT * FROM cypher('age_schema', $$ MATCH path = (start_node {first_name: 'Zeke'})-[HasChild*1..5 {guardian_role: 'father'}]->(end_node {last_name: 'Flintstone'}) RETURN path $$) AS (path agtype);`

**to_rich_h**

- added to_rich_h method to nodes, edges and paths (displays additional context information for readability and represents data closer to the original age data)

**Generic Queries**

- ApacheAge::Node and ApacheAge::Edge can be used as the base for a query and return results instantiating the correct class (node, edge or path)

**Read Me** largely updated

**Query Values**

- data casting within query code (so that matches are accurate)
  * string
  * integer
  * decimal
  * date
  * datetime
  * boolean

Not implemented (on the rails side)
  * array
  * hash
  * json


## VERSION 0.6.4 - 2024-10-30

- **Query Sanitize**:
  * allow and sanitize query strings with multiple attributes, ie: `Person.where("find.first_name = ? AND find.last_name = ?", 'John', 'Doe')`
  NOTE: for now the following keyords MuST be in caps!
  ```
  operators = ['=', '>', '<', '<>', '>=', '<=', '=~', 'ENDS WITH', 'CONTAINS', 'STARTS WITH', 'IN', 'IS NULL', 'IS NOT NULL']
  separators = ["AND NOT", "OR NOT", "AND", "OR", "NOT"]
  ```

## VERSION 0.6.3 - 2024-10-27

- **Query Sanitize**:
  * sanitize strings using: id(find) = ?, 23 & find.first_name = ?, 'John'
    NOTE: this sanitization only works (so far) for strings containing ONE attribute. ie: `Person.where("find.first_name = ?", 'John')` or `Person.where("first_name = ?", 'John')` works but `Person.where("find.first_name = ? AND find.last_name = ?", 'John', 'Doe')` does not yet work

## VERSION 0.6.2 - 2024-09-30

- **Query Sanitize**
  * hash queries sanitized

## VERSION 0.6.1 - 2024-09-29

**Queries are not yet sanitize (injection filtered)!**

- **where nodes** - Edge and Node
- **where edges** - allow subquery on node attributes?
- **limit** - limit the number of results returned

## VERSION 0.6.0 - 2024-06-28

**Document showing errors**

**breaking changes**: update naming
  * renamed `Entities::Vertex` module to `Entities::Node`
  * renamed `UniqueVertex` to `UniqueNode`
  * rebamed `AgeTypeGenerator.create_type_for` to `Type::Factory.type_for`
  * move `lib/generators/*` intp `lib/apache_age/generators`

here is the [commit](https://github.com/marpori/rails_age_demo_app/commit/a6f0708f2bbc165eddbafe63896068a72d803b17) to see the changes te demo app to make it work for release 0.6.0

## VERSION 0.5.3 - 2024-06-23

- **Edge Scaffold** (generates edge, type, view and controller) - without start-/end-nodes types!?
  * add `rails generate apache_age:edge_scaffold HasJob employee_role`
  * add system test (to dummy app after scaffold_node is run)

- **Node Scaffold** (generates node, type, view and controller)
  * add system test (to dummy app after scaffold_node is run)

## VERSION 0.5.2 - 2024-06-16

- **Node Scaffold** (generates node, type, view and controller)
  * add `rails generate apache_age:node_scaffold Person first_name last_name age:integer`

## VERSION 0.5.1 - 2024-06-16 (yanked)

**yanked** (2024-06-16) - had an issue with the generator

- **Node Scaffold** (generates node, type, view and controller)
  * add `rails generate apache_age:node_scaffold Person first_name last_name age:integer`

## VERSION 0.5.0 - 2024-06-15

**breaking change**: renamed the validators to UniqueVertex and UniqueEdge

- **Edge Generator**
  * add `rails generate apache_age:edge HasPet owner_role`
    caveate: start_node and end_node are of type `:node` in the generator but can be changed manually in the class file - having trouble with the generator loading the types (the generator rejects custom types - but rails still works with custom types)

## VERSION 0.4.1 - 2024-06-15

- **Installer**
  * add optional: safe migrations with `bin/rails db:migrate` instead of using `bin/rails apache_age:migrate`
    (install using `bin/rails apache_age:override_db_migrate`)

## VERSION 0.4.0 - 2024-06-14

**breaking change**: type (:vertix) is now required in core for edges

- **Installer**
  * AGE types added to installer (with tests)

- **Node Generator**
  * add also creates node types (with tests)

- **Apache AGE Migrate**
  * add `bin/rails apache_age:migrate` runs `bin/rails db:migrate` followed by `bin/rails apache_age:config_schema` to fix the schema file after `bin/rails db:migrate`

## VERSION 0.3.2 - 2024-06-08

- **Node Generator**
  * add `rails generate apache_age:node Pets/Cat name age:integer` creates a node with a namespace and attributes at: `app/nodes/pets/cat.rb`
  * add `rails generate apache_age:node Cat name age:integer` creates a node with attributes at:  `app/nodes/cat.rb`
  * add `rails destroy apache_age:node Cat` deletes an existing node at: `app/nodes/cat.rb`

## VERSION 0.3.1 - 2024-06-02

- **Installer**
  * refactor into multiple independent tasks with tests

- **Documentation**
  * updated README with additional information
  * added `db/structure.sql` config to README

## VERSION 0.3.0 - 2024-05-28

- **Edges**
  * `find_by(start_node:, :end_node:, properties:)` to find an edge with specific nodes & properties (deprecated `find_edge`)

- **Installer** (`rails generate apache_age:install`)
  * copy Age PG Extenstion migration to `db/migrate`
  * run the AGE PG Migration
  * repair `db/schema.rb` (rails mangles schema after running pg extension)
  * update `database.yml` with schema search paths

NOTE: the `rails generate apache_age:install` can be run at any time to repair the schema (or other config) file if needed.

## VERSION 0.2.0 - 2024-05-26

- **Edges**
  * add class methods to `find_edge` (with {properties, end_id, start_id})
  * add missing methods to use in rails controllers
  * validate edge start- & end-nodes are valid
  * add unique edge validations

- **Nodes**
  * add missing methods to use in rails controllers
  * add unique node validations

## VERSION 0.1.0 - 2024-05-21

Initial release has the following features:

- **Nodes:**
  * `.create`, `.read`, `.update`, `.delete`, `.all`, `.find(by id)`, `.find_by(age_properties)`
  * verified with usage in a controller and views

- **Edges:**
  *`.create`, `.read`, `.update`, `.delete`, `.all`, `.find(by id)`, `.find_by(age_properties)`
  * verified with usage in a controller and views

- **Entities:**
  * `.all`, `.find(id)`, `.find_by(age_property)` use these when class, label, edge, node

These can be used within Rails applications using a Rails APIs including within controllers and views.
See the [README](README.md) for more information.
