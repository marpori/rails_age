# spec/lib/apache_age/validators/unique_edge_validator_spec.rb
require 'rails_helper'

RSpec.describe ApacheAge::Validators::UniqueEdgeValidator do
  before do
    class Person
      include ApacheAge::Entities::Vertex

      attribute :first_name, :string
      attribute :last_name, :string

      validates :first_name, :last_name, presence: true
      validates_with(
        ApacheAge::Validators::UniqueVertexValidator,
        attributes: %i[first_name last_name]
      )
    end

    class Pet
      include ApacheAge::Entities::Vertex

      attribute :species, :string
      attribute :pet_name, :string

      validates :species, :pet_name, presence: true
      validates_with(
        ApacheAge::Validators::UniqueVertexValidator,
        attributes: %i[species pet_name]
      )
    end

    class HasPet
      include ApacheAge::Entities::Edge

      attribute :caregiver_role, :string

      validates :caregiver_role, presence: true
      validates_with(
        ApacheAge::Validators::UniqueEdgeValidator,
        attributes: %i[caregiver_role start_node end_node]
      )
    end
  end

  # Remove the Pet class
  after do
    Object.send(:remove_const, :Pet)
    Object.send(:remove_const, :Person)
    Object.send(:remove_const, :HasPet)
  end

  context '.save' do
    subject { HasPet.create(**attributes) }

    let(:attributes) { { start_node: person, end_node: fido, caregiver_role: 'Primary Caregiver' } }
    let(:person) { Person.create(first_name: 'John', last_name: 'Doe') }
    let(:fido) { Pet.create(species: 'dog', pet_name: 'Fido') }
    let(:rex) { Pet.create(species: 'dog', pet_name: 'Rex') }

    context 'with unique record' do
      it { expect(subject).to be_valid }
      it { expect(subject.age_type).to eq('edge') }
      it { expect(subject.caregiver_role).to eq('Primary Caregiver') }
    end

    context 'with a duplicate record' do
      before { HasPet.create(start_node: person, end_node: rex, caregiver_role: 'Primary Caregiver') }

      it { expect(subject.age_type).to eq('edge') }
      it 'is not unique' do
        subject.end_node = rex
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:caregiver_role]).to include 'prpoerty combination not unique'
        expect(subject.errors.messages[:start_node]).to include 'node combination not unique'
        expect(subject.errors.messages[:end_node]).to include 'node combination not unique'
        expect(subject.errors.messages[:base]).to include 'record not unique'
      end
    end
  end

  context '.new' do
    subject { HasPet.new(**attributes) }

    let(:attributes) { { start_node: person, end_node: pet, caregiver_role: 'Primary Caregiver' } }
    let(:person) { Person.create(first_name: 'John', last_name: 'Doe') }
    let(:pet) { Pet.create(species: 'dog', pet_name: 'Fido') }

    context 'with unique record' do
      it { expect(subject).to be_valid }
      it { expect(subject.age_type).to eq('edge') }
    end

    context 'with missing required data' do
      let(:attributes) { { } }

      it { expect(subject.age_type).to eq('edge') }
      it '' do
        expect(subject).not_to be_valid
        expect(subject.errors[:end_node]).to include("can't be blank")
        expect(subject.errors[:start_node]).to include("can't be blank")
        expect(subject.errors[:caregiver_role]).to include("can't be blank")
      end
    end

    context 'with a duplicate record' do
      before { HasPet.create(start_node: person, end_node: pet, caregiver_role: 'Primary Caregiver') }

      it { expect(subject.age_type).to eq('edge') }
      it 'is not unique' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:caregiver_role]).to include 'prpoerty combination not unique'
        expect(subject.errors.messages[:start_node]).to include 'node combination not unique'
        expect(subject.errors.messages[:end_node]).to include 'node combination not unique'
        expect(subject.errors.messages[:base]).to include 'record not unique'
      end
    end
  end

  context '.create' do
    subject { Pet.create(species: 'dog', pet_name: 'Fido') }

    context 'when unique' do
      it { expect(subject).to be_valid }
      it { expect(subject).to be_persisted }
      it { expect(subject.species).to eq('dog') }
      it { expect(subject.pet_name).to eq('Fido') }
      it { expect(subject.age_type).to eq('vertex') }

      it 'saves' do
        expect(subject).to be_valid
        expect(subject).to be_persisted
      end
    end

    context 'when a duplicate' do
      before { Pet.create(species: 'dog', pet_name: 'Fido') }

      it { expect(subject).not_to be_persisted }
      it { expect(subject.species).to eq('dog') }
      it { expect(subject.pet_name).to eq('Fido') }
      it { expect(subject.age_type).to eq('vertex') }

      it 'is not unique' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:base]).to include 'record not unique'
        expect(subject.errors.messages[:species]).to include 'property combination not unique'
        expect(subject.errors.messages[:pet_name]).to include 'property combination not unique'
      end
    end
  end
end
