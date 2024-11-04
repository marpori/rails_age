module ApacheAge
  module Entities
    module Node
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Model
        include ActiveModel::Dirty
        include ActiveModel::Attributes
        include ActiveModel::Validations
        include ActiveModel::Validations::Callbacks

        attribute :id, :integer

        extend ApacheAge::Entities::ClassMethods
        include ApacheAge::Entities::CommonMethods
      end

      def age_type = 'vertex'

      # AgeSchema::Nodes::Company.create(company_name: 'Bedrock Quarry')
      # SELECT *
      # FROM cypher('age_schema', $$
      #     CREATE (company:Company {company_name: 'Bedrock Quarry'})
      # RETURN company
      # $$) as (Company agtype);
      def create_sql
        alias_name = age_alias || age_label.downcase
        sanitized_properties =
          self
            .to_h.reject { |k, v| k == :id }.reject { |k, v| v.nil? }
            .map { |k, v| "#{k}: #{ActiveRecord::Base.sanitize_sql(["?", v])}" }
            .join(', ')

        <<~SQL.squish
          SELECT *
          FROM cypher('#{age_graph}', $$
              CREATE (#{alias_name}:#{age_label} {#{sanitized_properties}})
          RETURN #{alias_name}
          $$) as (#{age_label} agtype);
        SQL
      end

      # So far just properties of string type with '' around them
      def update_sql
        alias_name = ActiveRecord::Base.sanitize_sql_like(age_alias || age_label.downcase)
        sanitized_set_clause = age_properties.map do |k, v|
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
              MATCH (#{alias_name}:#{age_label})
              WHERE id(#{alias_name}) = #{sanitized_id}
              SET #{sanitized_set_clause}
              RETURN #{alias_name}
          $$) as (#{age_label} agtype);
        SQL
      end
    end
  end
end
