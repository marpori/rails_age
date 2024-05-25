# Usage (within an Age Model)
# validates_with UniqueVertexValidator, attributes: [:first_name, :last_name, :gender]

# lib/apache_age/validators/unique_vertex_validator.rb
module ApacheAge
  module Validators
    class UniqueVertexValidator < ActiveModel::Validator
      def validate(record)
        attributes = options[:attributes]
        return if attributes.blank? || record.persisted?

        record_attribs = attributes.map { |attr| [attr, record.send(attr)] }.to_h.symbolize_keys
        query = record.class.find_by(record_attribs)
        attributes.each { record.errors.add(_1, 'attribute combination not unique') } if query.present?
      end
    end
  end
end
