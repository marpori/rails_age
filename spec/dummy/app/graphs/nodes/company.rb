module Nodes
  class Company
    include ApacheAge::Vertex

    attribute :company_name, :string
    validates :company_name, presence: true
  end
end
