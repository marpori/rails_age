# Change Log

## VERSION 0.4.0 - 2024-xx-xx

- **Edges**
  * `find_edge` is deprecated - use `find_by` with :start_node, :end_node to find an edge with specific nodes
- **cypher**
  * query support
  * paths support
  * select attributes support
- **Paths**
  * ?

## VERSION 0.3.1 - 2024-xx-xx

- **Genetator**
  * add `rails generate apache_age:node` to create a node model (with its type in initializer)
  * add `rails generate apache_age:edge` to create an edge model (with its type in initializer)
- **Installer**
  * refactored into multiple independent tasks?

## VERSION 0.3.0 - 2024-05-28

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
