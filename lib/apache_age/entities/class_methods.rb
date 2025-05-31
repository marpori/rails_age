module ApacheAge
  module Entities
    module ClassMethods
      # for now we only allow one predertimed graph
      def create(attributes)
        instance = new(**attributes)
        instance.save
        instance
      end

      def where(*attributes)
        query_builder = QueryBuilder.new(self)
        query_builder.where(*attributes)
      end

      def all = QueryBuilder.new(self).all
      def first = QueryBuilder.new(self).limit(1).first
      def find(id) = where(id: id).first

      def find_by(attributes)
        return nil if attributes.reject { |_k, v| v.blank? }.empty?

        where(attributes).limit(1).first
      end

      # Private stuff

      def age_graph = 'age_schema'
      def age_label = name.gsub('::', '__')
      def age_type = name.constantize.new.age_type

      def match_clause
        case age_type
        when 'vertex'
          # this allows us to Query for all nodes or a specific class of nodes
          self == ApacheAge::Node ? '(find)' : "(find:#{age_label})"
        when 'edge'
          # this allows us to Query for all edges or a specific class of edges
          self == ApacheAge::Edge ? '(start_node)-[find]->(end_node)' : "(start_node)-[find:#{age_label}]->(end_node)"
        when 'path'
          "(start_node)-[edge:#{@path_edge.gsub('::', '__')}*#{@path_length} #{path_properties}]->(end_node)"
        end
      end

      def execute_sql(cypher_sql) = ActiveRecord::Base.connection.execute(cypher_sql)

      def execute_find(cypher_sql) = execute_where(cypher_sql).first

      def execute_where(cypher_sql)
        age_results = ActiveRecord::Base.connection.execute(cypher_sql)
        return [] if age_results.values.count.zero?

        age_results.values.map do |value|
          json_data = value.first.split('::').first
          hash = JSON.parse(json_data)
          # once we have the record we use the label to find the class
          klass = hash['label'].gsub('__', '::').constantize
          attribs = hash.except('label', 'properties').merge(hash['properties']).symbolize_keys

          # knowing the class and attributes we can create a new instance (wether all results are of the same class or not)
          # This allows us to return results for, ApacheAge::Node, ApacheAge::Edge, or any specific type of node or edge
          klass.new(**attribs)
        end
      end

      private

      def where_node_clause(attributes)
        # # Make sure we're not treating a simple node attribute query as a start_node hash
        # # This fixes the issue with where(first_name: 'Barney') getting treated as a path query
        # if attributes.key?(:start_node) && attributes[:start_node].is_a?(Hash)
        #   # Handle the special case where start_node contains properties
        #   start_node_attrs = attributes[:start_node].map do |k, v|
        #     query_string = k == :id ? "id(find) = ?" : "find.#{k} = ?"
        #     ActiveRecord::Base.sanitize_sql([query_string, v])
        #   end.join(' AND ')
        #   return start_node_attrs
        # end

        # Normal case - regular node attributes
        build_core_where_clause(attributes)
      end

      def where_edge_clause(attributes)
        core_attributes = attributes.except(:end_id, :start_id, :end_node, :start_node)
        core_clauses = core_attributes.empty? ? nil : build_core_where_clause(core_attributes)

        end_id =
          if attributes[:end_id]
            attributes[:end_id]
          elsif attributes[:end_node].is_a?(Node)
            attributes[:end_node]&.id
          end
        where_end_id = end_id ? ActiveRecord::Base.sanitize_sql(["id(end_node) = ?", end_id]) : nil

        start_id =
          if attributes[:start_id]
            attributes[:start_id]
          elsif attributes[:start_node].is_a?(Node)
            attributes[:start_node]&.id
          end
        where_start_id = start_id ? ActiveRecord::Base.sanitize_sql(["id(start_node) = ?", start_id]) : nil

        where_end_attrs =
          if attributes[:end_node].is_a?(Hash)
            attributes[:end_node].map { |k, v| ActiveRecord::Base.sanitize_sql(["end_node.#{k} = ?", v]) }
          end
        where_start_attrs =
          if attributes[:start_node].is_a?(Hash)
            attributes[:start_node].map { |k, v| ActiveRecord::Base.sanitize_sql(["start_node.#{k} = ?", v]) }
          end

        [core_clauses, where_start_id, where_end_id, where_start_attrs, where_end_attrs]
          .flatten.compact.join(' AND ')
      end

      # def where_path_clause(attributes)
      # end

      def build_core_where_clause(attributes)
        attributes
          .compact
          .map do |k, v|
            if k == :id
              "id(find) = #{v}"
            else
              # Format the value appropriately based on its type
              formatted_value = format_for_cypher(k, v)
              "find.#{k} = #{formatted_value}"
            end
          end
          .join(' AND ')
      end

      # Formats a value appropriately for use in a Cypher query based on its type
      def format_for_cypher(attribute_name, value)
        return 'null' if value.nil?

        # Find the attribute type if possible
        attribute_type = attribute_types[attribute_name.to_s] if respond_to?(:attribute_types)

        # Format based on Ruby class if no attribute type info is available
        case
        when attribute_type.is_a?(ActiveModel::Type::Boolean) || value == true || value == false
          value.to_s # No quotes for booleans
        when attribute_type.is_a?(ActiveModel::Type::Integer) || value.is_a?(Integer)
          value.to_s # No quotes for integers
        when attribute_type.is_a?(ActiveModel::Type::Float) || attribute_type.is_a?(ActiveModel::Type::Decimal) || value.is_a?(Float) || value.is_a?(BigDecimal)
          value.to_s # No quotes for floats/decimals
        when (attribute_type.is_a?(ActiveModel::Type::Date) && (attribute_type.class != ActiveModel::Type::DateTime)) || value.class == Date
          "'#{value.strftime('%Y-%m-%d')}'" # Format dates as 'YYYY-MM-DD'
        when (attribute_type.is_a?(ActiveModel::Type::DateTime) && (attribute_type.class != ActiveModel::Type::Date)) || value.is_a?(Time) || value.is_a?(DateTime)
          utc_time = value.respond_to?(:utc) ? value.utc : value
          "'#{utc_time.strftime('%Y-%m-%d %H:%M:%S.%6N')}'" # Format datetime (not natively supported in AGE, so formatting is a workaround)
        # when value.is_a?(Array) || value.is_a?(Hash) || value.is_a?(Json)
        #   # For JSON data, serialize to JSON string and ensure it's properly quoted
        #   "'#{value.to_json.gsub("\'", "\\'")}'"
        # when value.is_a?(ActiveModel::Type::Array) ||value.is_a?(ActiveModel::Type::Hash) || value.is_a?(ActiveModel::Type::Json)
        #   # For JSON data, serialize to JSON string and ensure it's properly quoted
        #   "'#{value.to_json.gsub("\'", "\\'")}'"
        else
          # Default to string treatment with proper escaping
          "'#{value.to_s.gsub("\'", "\\'")}'"
        end
      end
    end
  end
end
