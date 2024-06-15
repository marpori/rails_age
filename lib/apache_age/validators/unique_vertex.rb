# lib/apache_age/validators/unique_vertex.rb

# Usage (within an Age Model)
# validates_with(
#   ApacheAge::Validators::UniqueVertex,
#   attributes: [:first_name, :last_name, :gender]
# )

module ApacheAge
  module Validators
    class UniqueVertex < ActiveModel::Validator
      def validate(record)
        allowed_keys = record.age_properties.keys
        attributes = options[:attributes]
        return if attributes.blank?

        record_attribs =
          attributes
          .map { |attr| [attr, record.send(attr)] }
          .to_h.symbolize_keys
          .slice(*allowed_keys)
        query = record.class.find_by(record_attribs)

        # if no match is found or if it finds itself, it's valid
        return if query.blank?  || (query.id == record.id)

        record.errors.add(:base, 'record not unique')
        attributes.each { record.errors.add(_1, 'property combination not unique') }
      end
    end
  end
end
