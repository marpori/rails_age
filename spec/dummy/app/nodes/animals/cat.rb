class Animals::Cat
  include ApacheAge::Entities::Node

  attribute :name, :string

  validates :name, presence: true

  # custom unique node validator (remove any attributes that are NOT important to uniqueness)
  validates_with(
    ApacheAge::Validators::UniqueNode,
    attributes: [:name]
  )
end
