module ApacheAge
  class Node
    include ApacheAge::Entities::Node

    attribute :label, :string
    attribute :properties
    # attribute :properties, :hash

    # def display = [label, properties&.values&.first].compact.join(' - ')
    def display
      info = properties&.values&.first
      info.blank? ? "#{label} (#{id})" : "#{info} (#{label})"
    end

    def self.all
      all_nodes_sql = <<~SQL
      SELECT *
      FROM cypher('age_schema', $$
          MATCH (node)
          RETURN node
      $$) as (node agtype);
      SQL
      age_results = ActiveRecord::Base.connection.execute(all_nodes_sql)
      return [] if age_results.values.count.zero?

      age_results.values.map do |result|
        json_string = result.first.split('::').first
        hash = JSON.parse(json_string)
        attribs = hash.slice('id', 'label').symbolize_keys
        attribs[:properties] = hash['properties'].symbolize_keys

        new(**attribs)
      end
    end
  end
end
