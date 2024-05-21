module ApacheAge
  module Vertex
    extend ActiveSupport::Concern
    # include ApacheAge::Entity

    included do
      include ActiveModel::Model
      include ActiveModel::Dirty
      include ActiveModel::Attributes

      attribute :id, :integer

      extend ApacheAge::ClassMethods
      include ApacheAge::CommonMethods
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
      <<-SQL
        SELECT *
        FROM cypher('#{age_graph}', $$
            CREATE (#{alias_name}#{self})
        RETURN #{alias_name}
        $$) as (#{age_label} agtype);
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
            MATCH (#{alias_name}:#{age_label})
            WHERE id(#{alias_name}) = #{id}
            SET #{set_caluse}
            RETURN #{alias_name}
        $$) as (#{age_label} agtype);
      SQL
    end
  end
end
