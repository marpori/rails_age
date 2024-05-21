# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Nodes::Company do
  describe '.new' do
    subject { described_class.new(**attributes) }

    context 'when all attributes are given' do
      let(:attributes) { { company_name: 'Rockport Querry' } }

      it { expect(subject).to be_valid }
      it { expect(subject.id).to be_nil }
      it { expect(subject.company_name).to eq attributes[:company_name] }
      it { expect(subject.age_properties).to eq attributes }
      it '#save' do
        expect(subject.save).to be_truthy
        expect(subject.id).to be_present
        expect(subject).to be_persisted
      end
    end

    context 'when required attributes are not given' do
      let(:attributes) { {} }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:company_name]).to include "can't be blank"
      end
    end
  end

  describe '.create' do
    subject { described_class.create(**attributes) }

    context 'when all attributes are given' do
      let(:attributes) { { company_name: 'Rockport Querry' } }

      it { expect(subject.id).to be_present }
      it { expect(subject).to be_persisted }
    end
  end
end
