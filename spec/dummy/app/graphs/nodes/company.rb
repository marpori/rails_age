module Nodes
  class Company
    include ApacheAge::Entities::Vertex

    attribute :company_name, :string
    validates :company_name, presence: true
  end
end
