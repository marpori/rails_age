module ApacheAge
  module Entities
    module Path
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Model
        include ActiveModel::Dirty
        include ActiveModel::Attributes

        attribute :id, :integer
        # attribute :label, :string
        attribute :end_id, :integer
        attribute :start_id, :integer
        # override with a specific node type in the defining class
        attribute :end_node
        attribute :start_node

        validates :end_node, :start_node, presence: true
        validate :validate_nodes

        extend ApacheAge::Entities::ClassMethods
        include ApacheAge::Entities::CommonMethods
      end
    end
  end
end
