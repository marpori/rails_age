# spec/lib/apache_age/validators/unique_vertex_validator_spec.rb
require 'rails_helper'

RSpec.describe ApacheAge::Validators::UniqueVertexValidator do
  before do
    class Pet
      include ApacheAge::Entities::Vertex
      attribute :species, :string
      attribute :pet_name, :string
      validates :species, :pet_name, presence: true

      validates_with(ApacheAge::Validators::UniqueVertexValidator, attributes: [:species, :pet_name])
    end
  end

  # Remove the Pet class
  after { Object.send(:remove_const, :Pet) }

  context '.new' do
    subject { Pet.new(species: 'dog', pet_name: 'Fido') }

    context 'with unique record' do
      it { expect(subject).to be_valid }
      it { expect(subject.species).to eq('dog') }
      it { expect(subject.pet_name).to eq('Fido') }
      it { expect(subject.age_type).to eq('vertex') }
    end

    context 'with a duplicate record' do
      before { Pet.create(species: 'dog', pet_name: 'Fido') }

      it { expect(subject.species).to eq('dog') }
      it { expect(subject.pet_name).to eq('Fido') }
      it { expect(subject.age_type).to eq('vertex') }
      it 'is not unique' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:species]).to include 'attribute combination not unique'
        expect(subject.errors.messages[:pet_name]).to include 'attribute combination not unique'
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
        expect(subject.errors.messages[:species]).to include 'attribute combination not unique'
        expect(subject.errors.messages[:pet_name]).to include 'attribute combination not unique'
      end
    end
  end
end
