# Usage (within an Age Model)
# validates_with UniqueEdgeValidator, attributes: [:employee_role, :start_node, :end_node]
# validates_with UniqueEdgeValidator, attributes: [:start_id, :employee_role, :end_id]
#
module ApacheAge
  module Validators
    class UniqueEdgeValidator < ActiveModel::Validator
      def validate(record)
        attributes = options[:attributes]

        # unless record.end_node.blank? || record.end_node.valid? || record.end_node.persisted?
        #   record.errors.add(:end_id, 'invalid node')
        # end
        # unless record.start_node.blank? || record.start_node.valid? || record.start_node.persisted?
        #   record.errors.add(:start_id, 'invalid node')
        # end

        end_query = record.end_node ? query_node(record.end_node) : nil
        start_query = record.start_node ? query_node(record.start_node) : nil
        return if attributes.blank? && (end_query.blank? || start_query.blank?)

        edge_attribs = attributes.map { |attr| [attr, record.send(attr)] }.to_h.symbolize_keys
        edge_attribs[:end_id] = end_query&.id
        edge_attribs[:start_id] = start_query&.id

        query = record.class.find_edge(edge_attribs.compact)
        return if query.blank? || (query.id == record.id)

        record.errors.add(:base, 'attribute combination not unique')
        record.errors.add(:end_node, 'attribute combination not unique')
        record.errors.add(:start_node, 'attribute combination not unique')
        attributes.each { record.errors.add(_1, 'attribute combination not unique') }
      end

      private

      def query_node(node) = node.persisted? ? node.class.find(node.id) : node.class.find_by(node.age_properties)
    end
  end
end
