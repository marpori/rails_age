# frozen_string_literal: true

require 'rails_helper'

# useful when you do not ye know the type
RSpec.describe ApacheAge::Entities::Entity do
  let(:dino) { Pet.create(species: 'dinosaur', pet_name: 'Dino') }
  let(:juliet) { Pet.create(species: 'dinosaur', pet_name: 'Juliet') }
  let(:puss) { Pet.create(species: 'saber-toothed cat', pet_name: 'Baby Puss') }

  before do
    class Pet
      include ApacheAge::Entities::Vertex
      attribute :species, :string
      attribute :pet_name, :string
      validates :species, :pet_name, presence: true
    end

    dino
    juliet
    puss
  end

  # Remove the Pet class
  after { Object.send(:remove_const, :Pet) }

  context '.find' do
    subject { ApacheAge::Entities::Entity.find(id) }

    let(:id) { dino.id }

    it 'can be found by ID' do
      expect(subject.to_h).to eq(dino.to_h)
    end
  end

  context '.find_by' do
    subject { ApacheAge::Entities::Entity.find_by(attributes) }

    let(:attributes) { { pet_name: dino.pet_name, species: dino.species } }

    it 'can be found by pet_name' do
      expect(subject.to_h).to eq(dino.to_h)
    end
  end
end
