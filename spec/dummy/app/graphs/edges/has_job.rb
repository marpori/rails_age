module Edges
  class HasJob
    include ApacheAge::Entities::Edge

    attribute :employee_role, :string
    attribute :start_node, :person
    attribute :end_node, :company

    validates :employee_role, presence: true
    validate :validate_unique
    # validates_with(
    #   ApacheAge::Validators::UniqueEdgeValidator,
    #   attributes: %i[employee_role start_node end_node]
    # )

    private

    def validate_unique
      ApacheAge::Validators::UniqueEdgeValidator
        .new(attributes: %i[employee_role start_node end_node])
        .validate(self)
    end
  end
end
