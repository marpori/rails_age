module ApacheAge
  module Entities
    module Edge
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Model
        include ActiveModel::Dirty
        include ActiveModel::Attributes
        include ActiveModel::Validations
        include ActiveModel::Validations::Callbacks

        attribute :id, :integer
        # attribute :label, :string
        attribute :end_id, :integer
        attribute :start_id, :integer
        # override with a specific node type in the defining class
        attribute :end_node
        attribute :start_node

        validates :end_node, :start_node, presence: true
        validate :validate_nodes

        extend ApacheAge::Entities::ClassMethods
        include ApacheAge::Entities::CommonMethods
      end

      def initialize(**attributes)
        super
        self.end_id ||= end_node.id if end_node
        self.start_id ||= start_node.id if start_node
        self.end_node ||= Entity.find(end_id) if end_id
        self.start_node ||= Entity.find(start_id) if start_id
      end

      def age_type = 'edge'
      def end_class = end_node.class
      def start_class = start_node.class
      def end_node_class = end_node.class
      def start_node_class = start_node.class

      # Private methods

      # Custom validation method to validate start_node and end_node
      def validate_nodes
        errors.add(:start_node, 'invalid') if start_node && !start_node.valid?
        errors.add(:end_node, 'invalid') if end_node && !end_node.valid?
      end

      # Discover attribute class
      # name_type = model.class.attribute_types['name']
      # age_type = model.class.attribute_types['age']
      # company_type = model.class.attribute_types['company']
      # # Determine the class from the attribute type (for custom types)
      # name_class = name_type.class # This will generally be ActiveModel::Type::String
      # age_class = age_type.class   # This will generally be ActiveModel::Type::Integer
      # # For custom types, you may need to look deeper
      # company_class = company_type.cast_type.class

      # AgeSchema::Edges::HasJob.create(
      #   start_node: fred, end_node: quarry, employee_role: 'Crane Operator'
      # )
      # SELECT *
      # FROM cypher('age_schema', $$
      #     MATCH (start_vertex:Person), (end_vertex:Company)
      #     WHERE id(start_vertex) = 1125899906842634 and id(end_vertex) = 844424930131976
      #     CREATE (start_vertex)-[edge:HasJob {employee_role: 'Crane Operator'}]->(end_vertex)
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
end
