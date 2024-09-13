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

  describe '.where' do
    let(:fred) {
      described_class.new(
        first_name: 'Fred',
        nick_name: 'Fred',
        last_name: 'Flintstone',
        given_name: 'Flintstone',
        gender: 'male'
      )
    }
    let(:wilma) {
      described_class.new(
        first_name: 'Wilma',
        nick_name: 'Wilma',
        last_name: 'Flintstone',
        given_name: 'Slaghoople',
        gender: 'female'
      )
    }
    let(:pebbles) {
      described_class.new(
        first_name: 'Pebbles Wilma',
        nick_name: 'Pebbles',
        last_name: 'Flintstone',
        given_name: 'Flintstone',
        gender: 'female'
      )
    }
    let(:barney) {
      described_class.new(
        first_name: 'Barney',
        nick_name: 'Barney',
        last_name: 'Rubble',
        given_name: 'Rubble',
        gender: 'male'
      )
    }
    let(:betty) {
      described_class.new(
        first_name: 'Betty',
        nick_name: 'Betty',
        last_name: 'Rubble',
        given_name: 'McBricker',
        gender: 'female'
      )
    }
    let(:bamm_bamm) {
      described_class.new(
        first_name: 'Bamm Bamm',
        nick_name: 'Bamm Bamm',
        last_name: 'Rubble',
        given_name: 'Rubble',
        gender: 'male'
      )
    }
    before do
      fred.save
      wilma.save
      pebbles.save
      barney.save
      betty.save
      bamm_bamm.save
    end

    context 'simple .where' do
      subject { described_class.where(gender: 'male') }

      it 'returns men' do
        expect(subject.all.count).to eq(3)
        expect(subject.all.map(&:id)).to match_array([fred, barney, bamm_bamm].map(&:id))
      end
    end

    context 'compound .where attributes' do
      subject { described_class.where(gender: 'female', last_name: 'Flintstone') }

      it 'returns Flintstone women' do
        expect(subject.all.count).to eq(2)
        expect(subject.all.map(&:id)).to match_array([wilma, pebbles].map(&:id))
      end
    end

    context 'with limit and order' do
      subject {
        described_class.where(gender: 'female', last_name: 'Flintstone').order(:first_name).limit(1)
      }

      it 'returns Flintstone women' do
        expect(subject.all.count).to eq(1)
        expect(subject.all.map(&:id)).to match_array([pebbles].map(&:id))
      end
    end


    context 'with return (cypher "select")' do
      subject {
        described_class
          .where(gender: 'female', last_name: 'Flintstone')
          .return(:first_name, :last_name)
          .order(:first_name)
          .limit(1)
      }

      it 'returns Flintstone women' do
        expect(subject.all.count).to eq(1)
        expect(subject.all).to eq( [{ first_name: 'Pebbles Wilma', last_name: 'Flintstone' }] )
      end
    end

    context 'multiple .where statements' do
      subject { described_class.where(gender: 'female').where(last_name: 'Flintstone') }

      it 'returns Flintstone women' do
        expect(subject.all.count).to eq(2)
        expect(subject.all.map(&:id)).to match_array([wilma, pebbles].map(&:id))
      end
    end
  end
end
