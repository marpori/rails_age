# Usage (within an Age Model)
# validates_with UniqueEdgeValidator, attributes: [:employee_role, :start_node, :end_node]
# validates_with UniqueEdgeValidator, attributes: [:start_id, :employee_role, :end_id]

class UniqueEdgeValidator < ActiveModel::Validator
  def validate(record)
    attributes = options[:attributes]

    # remove ids from attributes
    # do a find_by on the attributes
    # if it exists, add an error to the record
    # if an edge and the start_id and end_id are persisted,
    # or start_node and end_node are persisted, then error
    # query = record.class.where(attributes.map { |attr| [attr, record.send(attr)] }.to_h)
    # query = query.where.not(id: record.id) if record.persisted? # Exclude self in case of update

    if query.exists?
      attributes.each do |attribute|
        record.errors.add(attribute, 'combination must be unique')
      end
    end
  end
end
