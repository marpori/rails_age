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

      def create_sql
        self.start_node = start_node.save unless start_node.persisted?
        self.end_node = end_node.save unless end_node.persisted?

        start_node_age_label = ActiveRecord::Base.sanitize_sql(start_node.age_label)
        end_node_age_label = ActiveRecord::Base.sanitize_sql(end_node.age_label)
        sanitized_start_id = ActiveRecord::Base.sanitize_sql(["?", start_node.id])
        sanitized_end_id = ActiveRecord::Base.sanitize_sql(["?", end_node.id])
        # cant use sanitize_sql_like because it escapes the % and _ characters
        # label_name = ActiveRecord::Base.sanitize_sql_like(age_label)

        reject_keys = %i[id start_id end_id start_node end_node]
        sanitized_properties =
          self.to_h.reject { |k, _v| reject_keys.include?(k) }.reject { |_k, v| v.nil? }
            .map { |k, v| "#{k}: #{ActiveRecord::Base.sanitize_sql(["?", v])}" }
            .join(', ')
        <<-SQL
          SELECT *
          FROM cypher('#{age_graph}', $$
              MATCH (from_node:#{start_node_age_label}), (to_node:#{end_node_age_label})
              WHERE id(from_node) = #{sanitized_start_id} AND id(to_node) = #{sanitized_end_id}
              CREATE (from_node)-[edge:#{age_label} {#{sanitized_properties}}]->(to_node)
              RETURN edge
          $$) as (edge agtype);
        SQL
      end

      # So far just properties of string type with '' around them
      def update_sql
        alias_name = age_alias || age_label.downcase
        set_clause =
          age_properties.map do |k, v|
            if v
              sanitized_value = ActiveRecord::Base.sanitize_sql(["?", v])
              "#{alias_name}.#{k} = #{sanitized_value}"
            else
              "#{alias_name}.#{k} = NULL"
            end
          end.join(', ')

        sanitized_id = ActiveRecord::Base.sanitize_sql(["?", id])

        <<-SQL
          SELECT *
          FROM cypher('#{age_graph}', $$
              MATCH ()-[#{alias_name}:#{age_label}]->()
              WHERE id(#{alias_name}) = #{sanitized_id}
              SET #{set_clause}
              RETURN #{alias_name}
          $$) as (#{age_label} agtype);
        SQL
      end
    end
  end
end
