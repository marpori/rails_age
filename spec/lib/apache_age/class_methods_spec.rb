# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApacheAge::ClassMethods do
  subject { dino }

  let(:dino) { Pet.create(species: 'dinosaur', pet_name: 'Dino') }
  let(:juliet) { Pet.create(species: 'dinosaur', pet_name: 'Juliet') }
  let(:puss) { Pet.create(species: 'saber-toothed cat', pet_name: 'Baby Puss') }

  before do
    class Pet
      include ApacheAge::Vertex
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

  context '.create' do
    subject { Pet.create(species: 'dog', pet_name: 'Fido') }

    it { expect(subject).to be_valid }
    it { expect(subject.age_type).to eq('vertex') }
    it { expect(subject.species).to eq('dog') }
    it { expect(subject.pet_name).to eq('Fido') }
  end

  context '.find' do
    it 'can be found by ID' do
      id = subject.id
      expect(Pet.find(id).to_h).to eq(subject.to_h)
    end
  end

  context '.find_by' do
    it 'can be found by pet_name' do
      pet_name = subject.pet_name
      species = subject.species
      expect(Pet.find_by(pet_name:, species:).to_h).to eq(subject.to_h)
    end
  end

  context '.all' do
    it 'can be found by pet_name' do
      pets = Pet.all
      expect(pets.count).to eq(3)
      expect(pets.map(&:pet_name)).to match_array(['Dino', 'Juliet', 'Baby Puss'])
    end
  end
end
