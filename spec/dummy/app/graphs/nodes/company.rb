module Nodes
  class Company
    include ApacheAge::Entities::Vertex

    attribute :company_name, :string

    validates :company_name, presence: true
    validates_with(
      ApacheAge::Validators::UniqueVertex,
      attributes: [:company_name]
    )
  end
end
