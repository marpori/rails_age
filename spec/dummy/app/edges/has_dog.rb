class HasDog
  include ApacheAge::Entities::Edge

  attribute :role, :string
  # recommendation for (start_node and end_node): change `:node` with the actual 'node' type
  # see `config/initializers/apache_age.rb` for the list of available node types
  attribute :start_node
  attribute :end_node

  validates :role, presence: true
  validates :start_node, presence: true
  validates :end_node, presence: true

  validate :validate_unique_edge

  private

  # custom unique edge validator (remove any attributes that are NOT important to uniqueness)
  def validate_unique_edge
    ApacheAge::Validators::UniqueEdge
      .new(attributes: [:role, :start_node, :end_node])
      .validate(self)
  end
end
