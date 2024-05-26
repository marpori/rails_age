module Edges
  class HasJob
    include ApacheAge::Entities::Edge

    attribute :employee_role, :string
    attribute :start_node, :person
    attribute :end_node, :company

    validates :employee_role, presence: true
    validates_with(
      ApacheAge::Validators::UniqueEdgeValidator,
      attributes: %i[employee_role start_node end_node]
    )
  end
end
