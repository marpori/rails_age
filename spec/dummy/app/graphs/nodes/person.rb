module Nodes
  class Person
    include ApacheAge::Vertex

    attribute :first_name, :string, default: nil
    attribute :last_name, :string, default: nil
    attribute :given_name, :string, default: nil
    attribute :nick_name, :string, default: nil
    attribute :gender, :string, default: nil

    validates :gender, :first_name, :last_name, :given_name, :nick_name,
              presence: true

    def initialize(**attributes)
      super
      # use unless present? since attributes when empty sets to "" by default
      self.nick_name = first_name unless nick_name.present?
      self.given_name = last_name unless given_name.present?
    end
  end
end
