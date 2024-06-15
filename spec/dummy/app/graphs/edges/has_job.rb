module Edges
  class HasJob
    include ApacheAge::Entities::Edge

    attribute :employee_role, :string
    attribute :start_node, :person
    attribute :end_node, :company

    validates :employee_role, presence: true
    validates :start_node, presence: true
    validates :end_node, presence: true

    validate :validate_unique_edge

    private

    def validate_unique_edge
      ApacheAge::Validators::UniqueEdge
        .new(attributes: %i[employee_role start_node end_node])
        .validate(self)
    end
  end
end
