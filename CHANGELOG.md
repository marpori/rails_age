# Change Log

## VERSION 0.3.0 - 2024-xx-xx

- **cypher**
  * query support
  * paths support
  * select attributes support
- **Paths**
  * ?

## VERSION 0.2.0 - 2024-05-26

- **Edges**
  * add class methods to find_edge(with {properties, end_id, start_id})
  * add missing methods to use in rails controllers
  * validate edge start- & end-nodes are valid
  * add unique edge validations
- **Nodes**
  * add missing methods to use in rails controllers
  * add unique node validations

## VERSION 0.1.0 - 2024-05-21

Initial release has the following features:

- **Nodes:**
  * Create, Read, Update, Delete & .find(by id), .find_by(age_property), .all
  * verified with usage in a controller and views
- **Edges:**
  * Create, Read, Update, Delete & .find(by id), .find_by(age_property), .all
  * verified with usage in a controller and views
- **Entities:**
  * find (by id), find_by(age_property), all; when class/label and/or edge/node is unknown)

These can be used within Rails applications using a Rails APIs including within controllers and views.
See the [README](README.md) for more information.
