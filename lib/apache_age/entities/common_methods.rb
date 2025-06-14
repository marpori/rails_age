module ApacheAge
  module Entities
    module CommonMethods
      # for now we just can just use one schema
      def age_graph = 'age_schema'
      def age_label = self.class.name.gsub('::', '__')
      def persisted? = id.present?
      def to_s = ":#{age_label} #{properties_to_s}"

      # default display value
      def display
        info = age_properties&.values&.first
        info.blank? ? "#{age_label} (#{id})" : "#{info} (#{age_label})"
      end

      def to_h
        base_h = attributes.to_hash
        if age_type == 'edge'
          # remove the nodes (in attribute form and re-add in hash form)
          base_h = base_h.except('start_node', 'end_node')
          base_h[:end_node] = end_node.to_h if end_node
          base_h[:start_node] = start_node.to_h if start_node
        end
        base_h.symbolize_keys
      end

      # Enhanced hash representation with display information
      # This provides more context without modifying the core attributes
      def to_rich_h
        # Start with the basic id and add the info string
        result = { _meta: "#{age_label} (#{age_type})", id: id }

        # Group all other attributes under properties
        properties_hash = {}
        attributes.to_hash.except('id').each do |key, value|
          # Skip node objects (we'll handle them specially below)
          next if %w[start_node end_node].include?(key)

          properties_hash[key.to_sym] = value
        end

        result[:properties] = properties_hash

        # Handle nested objects for edges
        if age_type == 'edge'
          result[:start_node] = start_node.to_rich_h if start_node&.respond_to?(:to_rich_h)
          result[:end_node] = end_node.to_rich_h if end_node&.respond_to?(:to_rich_h)
        end

        result
      end

      def update_attributes(attribs)
        attribs.except(id:).each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end
      end

      def update(attribs)
        update_attributes(attribs)
        save
      end

      def save
        return false unless valid?

        cypher_sql = (persisted? ? update_sql : create_sql)
        response_hash = execute_sql(cypher_sql)

        self.id = response_hash['id']

        if age_type == 'edge'
          self.end_id = response_hash['end_id']
          self.start_id = response_hash['start_id']
          # reload the nodes? (can we change the nodes?)
          # self.end_node = ApacheAge::Entity.find(end_id)
          # self.start_node = ApacheAge::Entity.find(start_id)
        end

        self
      end

      def destroy
        match_clause = (age_type == 'vertex' ? "(done:#{age_label})" : "()-[done:#{age_label}]->()")
        delete_clause = (age_type == 'vertex' ? 'DETACH DELETE done' : 'DELETE done')
        sanitized_id = ActiveRecord::Base.sanitize_sql(["id(done) = ?", id])
        cypher_sql =
          <<-SQL
          SELECT *
          FROM cypher('#{age_graph}', $$
              MATCH #{match_clause}
              WHERE #{sanitized_id}
              #{delete_clause}
              return done
          $$) as (deleted agtype);
          SQL

        hash = execute_sql(cypher_sql)
        return nil if hash.blank?

        self.id = nil
        self
      end
      alias destroy! destroy
      alias delete destroy

      # private

      def age_properties
        attrs = attributes.except('id')
        attrs = attrs.except('end_node', 'start_node', 'end_id', 'start_id') if age_type == 'edge'
        attrs.symbolize_keys
      end

      def age_hash
        hash =
          {
            id:,
            label: age_label,
            properties: age_properties
          }
        hash.merge!(end_id:, start_id:) if age_type == 'edge'
        hash.transform_keys(&:to_s)
      end

      def properties_to_s
        string_values =
          age_properties.each_with_object([]) do |(key, val), array|
            sanitized_val = ActiveRecord::Base.sanitize_sql(["?", val])
            array << "#{key}: #{sanitized_val}"
          end
        "{#{string_values.join(', ')}}"
      end

      def age_alias
        return nil if id.blank?

        # we start the alias with a since we can't start with a number
        'a' + Digest::SHA256.hexdigest(id.to_s).to_i(16).to_s(36)[0..9]
      end

      def execute_sql(cypher_sql)
        age_result = ActiveRecord::Base.connection.execute(cypher_sql)
        age_type = age_result.values.first.first.split('::').last
        json_data = age_result.values.first.first.split('::').first
        # json_data = age_result.to_a.first.values.first.split("::#{age_type}").first

        JSON.parse(json_data)
      end
    end
  end
end
