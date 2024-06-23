module Nodes
  class Company
    include ApacheAge::Entities::Node

    attribute :company_name, :string

    validates :company_name, presence: true
    validates_with(
      ApacheAge::Validators::UniqueNode,
      attributes: [:company_name]
    )
  end
end
