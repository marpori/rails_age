# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApacheAge::CommonMethods do
  context 'with minimal namespacing' do
    subject { married_to }

    let(:fred) { CavePerson.new(name: 'Bamm-Bamm Rubble') }
    let(:wilma) { CavePerson.new(name: 'Pebbles Flintstone') }
    let(:married_to) do
      MarriedTo.new(start_node: fred, end_node: wilma, since_year: 1963, role: 'husband')
    end

    before do
      class CavePerson
        include ApacheAge::Vertex
        attribute :name, :string
        validates :name, presence: true
      end

      class MarriedTo
        include ApacheAge::Edge
        attribute :role, :string
        attribute :since_year, :integer
        validates :role, :since_year, presence: true
      end
    end

    after do
      Object.send(:remove_const, :CavePerson)
      Object.send(:remove_const, :MarriedTo)
    end

    describe '.new (initialize)' do
      it { expect(subject.age_type).to eq('edge') }
      it { expect(subject.role).to eq('husband') }
      it { expect(subject.since_year).to eq(1963) }
      it { expect(subject.id).not_to be_present }
      it { expect(subject).not_to be_persisted }
    end

    describe '.to_h' do
      it 'returns a hash of the attributes' do
        expect(subject.to_h).to eq(
          id: nil,
          end_id: nil,
          start_id: nil,
          role: 'husband',
          since_year: 1963,
          start_node: fred.to_h,
          end_node: wilma.to_h
        )
      end
    end

    describe '#save' do
      it 'when not already persisted' do
        expect(subject.id).not_to be_present
        expect(subject).not_to be_persisted

        subject.save

        expect(subject.age_type).to eq('edge')
        expect(subject.role).to eq('husband')
        expect(subject.since_year).to eq(1963)
        expect(subject.id).to be_present
        expect(subject).to be_persisted

        id = subject.id
        spouse = MarriedTo.find(id)
        expect(spouse.id).to eq(id)
        expect(spouse.role).to eq('husband')
      end

      it 'when already persisted' do
        expect(subject.id).not_to be_present
        expect(subject).not_to be_persisted
        expect(subject.role).to eq('husband')

        subject.save
        expect(subject.id).to be_present

        subject.role = 'spouse'
        expect(subject.save).to be_truthy

        id = subject.id
        spouse = MarriedTo.find(id)
        expect(spouse.id).to eq(id)
        expect(spouse.role).to eq('spouse')
      end
    end

    describe '#update' do
      it '#update' do
        expect(subject.id).not_to be_present
        expect(subject).not_to be_persisted
        expect(subject.role).to eq('husband')
        expect(subject.since_year).to eq(1963)

        subject.save
        expect(subject.id).to be_present

        subject.update(role: 'spouse', since_year: 1964)
        expect(subject.save).to be_truthy

        id = subject.id
        spouse = MarriedTo.find(id)
        expect(spouse.id).to eq(id)
        expect(spouse.role).to eq('spouse')
        expect(subject.since_year).to eq(1964)
      end
    end

    describe '#destroy' do
      it 'removes an edge' do
        subject.save
        id = subject.id
        expect(subject.id).to be_present

        deleted = subject.destroy
        expect(deleted.id).not_to be_present

        expect(MarriedTo.find(id)).to be_nil
      end

      it 'removes a node' do
        fred.save
        id = fred.id
        expect(fred.id).to be_present

        deleted = fred.destroy
        expect(deleted.id).not_to be_present

        expect(CavePerson.find(id)).to be_nil
      end
    end
  end
end
