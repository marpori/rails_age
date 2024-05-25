module Edges
  class HasJob
    include ApacheAge::Edge

    attribute :employee_role, :string
    attribute :start_node, :person
    attribute :end_node, :company

    validates :employee_role, presence: true
  end
end
