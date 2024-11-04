module ApacheAge
  class Path
    include ApacheAge::Entities::Path

    attr_reader :query_builder, :path_edge, :path_length, :path_properties

    class << self
      def age_type = 'path'

      def cypher(path_edge: nil, path_length: nil, path_properties: {}, graph_name: nil)
        unless path_edge.nil? || path_edge.ancestors.include?(ApacheAge::Entities::Edge)
          raise ArgumentError, 'Path edge must be a valid edge class'
        end

        @path_edge = path_edge ? path_edge.name.gsub('::', '__') : nil
        @path_length = path_length ? "*#{path_length}" : "*"
        @path_properties = path_properties.blank? ? nil : " {#{path_properties.map { |k, v| "#{k}: '#{v}'" }.join(', ')}}"
        @match_clause = "path = (start_node)-[#{@path_edge}#{@path_length}#{@path_properties}]->(end_node)"
        @query_builder =
          ApacheAge::Entities::QueryBuilder.new(
            self,
            graph_name:,
            return_clause: 'path',
            match_clause: @match_clause
          )
          # @query_builder =
          #   ApacheAge::Entities::QueryBuilder.new(
          #     self,
          #     graph_name:,
          #     return_clause: 'path',
          #     match_clause: @match_clause,
          #     path_edge: @path_edge,
          #     path_length: @path_length,
          #     path_properties: @path_properties
          #   )
      end

      # def match_clause
      #   @match_clause = "path = (start_node)-[#{@path_edge}#{@path_length}#{@path_properties}]->(end_node)"
      # end

      def match(match_string)
        @match_clause = match_string
        self
      end

      # Delegate additional methods like `where`, `limit`, etc., to `QueryBuilder`
      def where(*args)
        @query_builder.where(*args)
        self
      end

      def order(ordering)
        @query_builder.order(ordering)
        self
      end

      def limit(limit_value)
        @query_builder.limit(limit_value)
        self
      end

      def return(*variables)
        @query_builder.return(*variables)
        self
      end

      # Executes the query and returns results
      def execute
        @query_builder.execute
      end

      def first
        @query_builder.first
      end

      def all
        @query_builder.all
      end

      # Build the final SQL query
      def to_sql
        @query_builder.to_sql
      end

      # private

      def execute_where(cypher_sql)
        age_results = ActiveRecord::Base.connection.execute(cypher_sql)
        return [] if age_results.values.count.zero?

        age_results.values.map do |row|
          path_data = row.first.split('::path').first
          # [1..-2] - removes leading and trailing brackets
          elements = path_data[1..-2].split(/(?<=\}::vertex,)|(?<=\}::edge,)/)
          elements.map do |element|
            path_hash = JSON.parse(element.sub("::vertex,", "").sub("::vertex", "").sub("::edge,", "").sub("::edge", "").strip)
            path_klass = path_hash['label'].gsub('__', '::').constantize
            path_attribs = path_hash.except('label', 'properties').merge(path_hash['properties']).symbolize_keys
            path_klass.new(**path_attribs)
          end
        end
      end
    end
  end
end
