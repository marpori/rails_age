module ApacheAge
  class Cypher
    class << self
      attr_accessor :model_class
    end

    def initialize(graph_name = 'age_schema')
      @graph_name = graph_name
      @query = ""
      @as_type = "result agtype"
    end

    def match(pattern)
      @query += "MATCH #{pattern} "
      self
    end

    # WITH n.name as name, n.age as age
    # WITH otherPerson, count(*) AS foaf WHERE foaf > 1
    # with has a lot of cases - see docs
    def with(*conditions)
      @query += "WITH #{variables.join(', ')} "
      self
    end

    def where(*conditions)
      condition_str = conditions.join(' AND ')
      # @query += "WHERE #{condition_str} "
      # If there's already a WHERE clause in the query, append to it (they need to be adjacent!)
      @query += (@query.include?("WHERE") ? " AND #{condition_str} " : "WHERE #{condition_str} ")
      self
    end

    # ORDER BY n.age DESC, n.name ASC
    def order_by(*conditions)
      @query += "ORDER BY #{variables.join(', ')} "
      self
    end

    # can use full names n.name or aliases (with) name
    def return(*variables)
      @query += "RETURN #{variables.join(', ')} "
      self
    end

    def create(node)
      @query += "CREATE #{node} "
      self
    end

    def set(properties)
      @query += "SET #{properties} "
      self
    end

    def remove(property)
      @query += "REMOVE #{property} "
      self
    end

    def delete(entity)
      @query += "DELETE #{entity} "
      self
    end

    def merge(pattern)
      @query += "MERGE #{pattern} "
      self
    end

    def skip(count)
      @query += "SKIP #{count} "
      self
    end

    def limit(count)
      @query += "LIMIT #{count} "
      self
    end

    def as(type)
      @as_type = type
      self
    end

    def to_cypher
      "SELECT * FROM cypher('#{@graph_name}', $$ #{@query.strip} $$) AS (#{@as_type});"
    end

    def execute
      cypher_sql = to_cypher
      ActiveRecord::Base.connection.execute(cypher_sql)
    end
  end
end
