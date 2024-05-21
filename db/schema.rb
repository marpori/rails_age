ActiveRecord::Schema[7.1].define(version: 2024_05_21_062349) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  # Allow age extension
  execute('CREATE EXTENSION IF NOT EXISTS age;')

  # Load the age code
  execute("LOAD 'age';")

  # Load the ag_catalog into the search path
  execute('SET search_path = ag_catalog, "$user", public;')

  # Create age_schema graph if it doesn't exist
  execute("SELECT create_graph('age_schema');")
end
