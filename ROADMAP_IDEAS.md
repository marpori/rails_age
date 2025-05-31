# Roadmap Ideas

## VERSION 0.7.1 ? - xxxx-xx-xx

**Path Generators**

- parse path into nodes and edges (helpful?)
  - add `rails generate apache_age:path_scaffold HasJobPath`
  - add `rails generate apache_age:path_scaffold HasJobPath start_node:person end_node:company`

## VERSION 0.8.0 ? - xxxx-xx-xx

- **AGE Schema override**
- **Multiple AGE Schema**
- **cypher queries** (like active record queries)
  * schema override
  * query support
  * paths support
  * select attributes support


## VERSION 0.9.0 ? - xxxx-xx-xx
- **AGE visual paths graph**
  * add `rails generate apache_age:visualize`


## VERSION 0.9.1 ? - xxxx-xx-xx

- **Edge Generator**
  * add start-/end-nodes types to edge generator (would make scaffold easier), ie:
    `rails generate apache_age:edge HasPet owner_role start_node:person end_node:pet`
    with property and specified start-/end-nodes (person and pet nodes must have already been created)

- **Edge Scaffold** with node types?
  * add `rails generate apache_age:edge_scaffold HasJob employee_role start_node:person end_node:company`
