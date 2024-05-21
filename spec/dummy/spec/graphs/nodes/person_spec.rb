# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Nodes::Person do
  describe '.new' do
    subject { described_class.new(**attributes) }

    context 'when all attributes are given' do
      let(:attributes) do
        {
          first_name: 'Pebbles Wilma',
          nick_name: 'Pebbles',
          last_name: 'Rubble',
          given_name: 'Flintstone',
          gender: 'female'
        }
      end
      it { expect(subject.id).to be_nil }
      it { expect(subject.first_name).to eq attributes[:first_name] }
      it { expect(subject.age_properties).to eq attributes }
      it '#save' do
        expect(subject.save).to be_truthy
        expect(subject.id).to be_present
        expect(subject).to be_persisted
      end
    end

    context 'when required attributes are given' do
      let(:attributes) do
        {
          first_name: 'Fred',
          last_name: 'Flintstone',
          gender: 'male'
        }
      end
      let(:properties) do
        {
          first_name: 'Fred',
          nick_name: 'Fred',
          last_name: 'Flintstone',
          given_name: 'Flintstone',
          gender: 'male'
        }
      end

      it { expect(subject.id).to be_nil }
      it { expect(subject.first_name).to eq attributes[:first_name] }
      it { expect(subject.nick_name).to eq attributes[:first_name] }
      it { expect(subject.last_name).to eq attributes[:last_name] }
      it { expect(subject.given_name).to eq attributes[:last_name] }
      it { expect(subject.age_properties).to eq properties }
    end

    context 'when required attributes are not given' do
      let(:attributes) { {} }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:first_name]).to include "can't be blank"
        expect(subject.errors.messages[:nick_name]).to include "can't be blank"
        expect(subject.errors.messages[:last_name]).to include "can't be blank"
        expect(subject.errors.messages[:given_name]).to include "can't be blank"
        expect(subject.errors.messages[:gender]).to include "can't be blank"
      end
    end
  end

  describe '.create' do
    subject { described_class.create(**attributes) }

    context 'when all attributes are given' do
      let(:attributes) do
        {
          first_name: 'Pebbles Wilma',
          nick_name: 'Pebbles',
          last_name: 'Rubble',
          given_name: 'Flintstone',
          gender: 'female'
        }
      end

      it { expect(subject.id).to be_present }
      it { expect(subject).to be_persisted }
    end
  end
end
