# Usage (within an Age Model)
# validates_with UniqueEdgeValidator, attributes: [:employee_role, :start_node, :end_node]
# validates_with UniqueEdgeValidator, attributes: [:start_id, :employee_role, :end_id]
#
module ApacheAge
  module Validators
    class UniqueEdgeValidator < ActiveModel::Validator
      def validate(record)
        allowed_keys = record.age_properties.keys
        attributes = options[:attributes] || []

        edge_attribs =
          attributes
          .map { |attr| [attr, record.send(attr)] }.to_h
          .symbolize_keys
          .slice(*allowed_keys)

        possible_end_keys = [:end_id, 'end_id', :end_node, 'end_node']
        end_query =
          if possible_end_keys.any? { |key| attributes.include?(key) }
            end_query = query_node(record.end_node)
            edge_attribs[:end_id] = end_query&.id
            end_query
          end

        possible_start_keys = [:start_id, 'start_id', :start_node, 'start_node']
        start_query =
          if possible_start_keys.any? { |key| attributes.include?(key) }
            start_query = query_node(record.start_node)
            edge_attribs[:start_id] = start_query&.id
            start_query
          end
        return if attributes.blank? && (end_query.blank? || start_query.blank?)

        query = record.class.find_edge(edge_attribs.compact)
        return if query.blank? || (query.id == record.id)

        record.errors.add(:base, 'attribute combination not unique')
        record.errors.add(:end_node, 'attribute combination not unique')
        record.errors.add(:start_node, 'attribute combination not unique')
        attributes.each { record.errors.add(_1, 'attribute combination not unique') }
      end

      private

      def query_node(node)
        return nil if node.blank?

        node.persisted? ? node.class.find(node.id) : node.class.find_by(node.age_properties)
      end
    end
  end
end
