# TODO

- [x] Figure out / test how to add unique constraints and validations to nodes and edges
- [x] Simplify setup with `rails_age:install`
- [x] create a generator for node
- [x] Safe migrations with `bin/rails apache_age:migrate`
- [x] Safe migrations with `bin/rails db:migrate` (using installer `bin/rails apache_age:override_db_migrate`)
- [x] create a generator for edge (currntly can't specify start_node and end_node types in generator)
      `rails generate apache_age:edge HasJob employee_role begin_date:date`
- [x] edge type generation in `config/initializers/types.rb`
- [x] create a generator for node_scaffold
- [x] create a generator for edge_scaffold
- [x] Test mismatched node types within edges
- [x] Fix validation errors display
- [ ] support for AGE paths (nodes and edges) combined
- [ ] support for AGE cypher queries (nodes, edges, paths, and select attributes)
- [ ] support for multiple AGE schemas
- [ ] Enforce Private and Protected methods
- [ ] Add additional data-types for AGE properties (Arrays, Hashes, etc.)
- [ ] allow edge generator to use custom types for start_node and end_node, ie:
      `rails generate apache_age:edge HasPet caretaker_role start_node:person end_node:pet`
