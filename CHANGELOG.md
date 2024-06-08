# Change Log

## VERSION 0.4.0 - 2024-xx-xx

- **cypher**
  * query support
  * paths support
  * select attributes support
- **Paths**
  * ?

## VERSION 0.3.4 - 2024-xx-xx

- **Type Generators**
  * add `rails generate apache_age:type`
  * add `rails generate apache_age:node_type`
  * add `rails generate apache_age:edge_type`

## VERSION 0.3.3 - 2024-xx-xx

- **Edge Generator**
  * add `rails generate apache_age:edge` to create an edge model


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
