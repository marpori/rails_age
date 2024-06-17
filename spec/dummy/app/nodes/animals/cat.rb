class Animals::Cat
  include ApacheAge::Entities::Vertex

  attribute :name, :string

  validates :name, presence: true

  # custom unique node validator (remove any attributes that are NOT important to uniqueness)
  validates_with(
    ApacheAge::Validators::UniqueVertex,
    attributes: [:name]
  )
end
