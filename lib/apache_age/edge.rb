module ApacheAge
  module Edge
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Model
      include ActiveModel::Dirty
      include ActiveModel::Attributes

      attribute :id, :integer
      attribute :end_id, :integer
      attribute :start_id, :integer
      attribute :end_node # :vertex
      attribute :start_node # :vertex

      validates :end_node, :start_node, presence: true

      extend ApacheAge::ClassMethods
      include ApacheAge::CommonMethods
    end

    def age_type = 'edge'

    # AgeSchema::Edges::WorksAt.create(
    #   start_node: fred, end_node: quarry, employee_role: 'Crane Operator'
    # )
    # SELECT *
    # FROM cypher('age_schema', $$
    #     MATCH (start_vertex:Person), (end_vertex:Company)
    #     WHERE id(start_vertex) = 1125899906842634 and id(end_vertex) = 844424930131976
    #     CREATE (start_vertex)-[edge:WorksAt {employee_role: 'Crane Operator'}]->(end_vertex)
    #     RETURN edge
    # $$) as (edge agtype);
    def create_sql
      self.start_node = start_node.save unless start_node.persisted?
      self.end_node = end_node.save unless end_node.persisted?
      <<-SQL
        SELECT *
        FROM cypher('#{age_graph}', $$
            MATCH (from_node:#{start_node.age_label}), (to_node:#{end_node.age_label})
            WHERE id(from_node) = #{start_node.id} and id(to_node) = #{end_node.id}
            CREATE (from_node)-[edge#{self}]->(to_node)
            RETURN edge
        $$) as (edge agtype);
      SQL
    end

    # So far just properties of string type with '' around them
    def update_sql
      alias_name = age_alias || age_label.downcase
      set_caluse =
        age_properties.map { |k, v| v ? "#{alias_name}.#{k} = '#{v}'" : "#{alias_name}.#{k} = NULL" }.join(', ')
      <<-SQL
        SELECT *
        FROM cypher('#{age_graph}', $$
            MATCH ()-[#{alias_name}:#{age_label}]->()
            WHERE id(#{alias_name}) = #{id}
            SET #{set_caluse}
            RETURN #{alias_name}
        $$) as (#{age_label} agtype);
      SQL
    end
  end
end
