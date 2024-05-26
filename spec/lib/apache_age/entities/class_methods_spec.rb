# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApacheAge::Entities::ClassMethods do
  context 'with a node' do
    subject { dino }

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

  context 'with an edge' do
    let(:person) { Person.create(first_name: 'John', last_name: 'Doe') }
    let(:fido) { Pet.create(species: 'dog', pet_name: 'Fido') }
    let(:rex) { Pet.create(species: 'dog', pet_name: 'Rex') }
    let(:has_fido) { HasPet.create(start_node: person, end_node: fido, caregiver_role: 'Primary Caregiver') }
    let(:has_rex) { HasPet.create(start_node: person, end_node: rex, caregiver_role: 'Secondary Caregiver') }

    before do
      class Person
        include ApacheAge::Entities::Vertex
        attribute :first_name, :string
        attribute :last_name, :string

        validates :first_name, :last_name, presence: true
        validates_with(ApacheAge::Validators::UniqueVertexValidator, attributes: [:first_name, :last_name])
      end

      class Pet
        include ApacheAge::Entities::Vertex
        attribute :species, :string
        attribute :pet_name, :string

        validates :species, :pet_name, presence: true
        validates_with(ApacheAge::Validators::UniqueVertexValidator, attributes: [:species, :pet_name])
      end

      class HasPet
        include ApacheAge::Entities::Edge
        attribute :caregiver_role, :string

        validates :caregiver_role, presence: true
        validates_with(ApacheAge::Validators::UniqueEdgeValidator, attributes: [:caregiver_role])
      end

      has_fido
      has_rex
    end

    # Remove the Pet class
    after do
      Object.send(:remove_const, :Pet)
      Object.send(:remove_const, :Person)
      Object.send(:remove_const, :HasPet)
    end

    context '.find_edge' do
      context 'with node_ids no attributes' do
        subject { HasPet.find_edge(start_id: person.id, end_id: fido.id) }

        it { expect(subject.id).to eq has_fido.id }
      end

      context 'with node_ids no attributes' do
        subject { HasPet.find_edge(caregiver_role: has_fido.caregiver_role, start_id: person.id, end_id: fido.id) }

        it { expect(subject.id).to eq has_fido.id }
      end

      context 'with one node_ids & attributes' do
        subject { HasPet.find_edge(caregiver_role: has_fido.caregiver_role, end_id: fido.id) }

        it { expect(subject.id).to eq has_fido.id }
      end

      context 'with attributes only' do
        subject { HasPet.find_edge(caregiver_role: has_fido.caregiver_role) }

        it { expect(subject.id).to eq has_fido.id }
      end

      context 'with node objects' do
        subject { HasPet.find_edge(start_node: person, end_node: fido) }

        it { expect(subject.id).to eq has_fido.id }
      end

      context 'with node objects no attributes' do
        subject { HasPet.find_edge(caregiver_role: has_fido.caregiver_role, start_node: person, end_node: fido) }

        it { expect(subject.id).to eq has_fido.id }
      end

      context 'with one node ids & attributes' do
        subject { HasPet.find_edge(caregiver_role: has_fido.caregiver_role, end_node: fido) }

        it { expect(subject.id).to eq has_fido.id }
      end
    end

    context '.find' do
      subject { HasPet.find(has_fido.id) }

      it { expect(subject.id).to eq has_fido.id }
    end

    context '.find_by' do
      subject { HasPet.find_by(caregiver_role: has_fido.caregiver_role) }

      it { expect(subject.id).to eq has_fido.id }
    end

    context '.all' do
      subject { HasPet.all }

      it { expect(subject.count).to eq(2) }
      it { expect(subject.map(&:caregiver_role)).to match_array(['Primary Caregiver', 'Secondary Caregiver']) }
    end
  end
end
