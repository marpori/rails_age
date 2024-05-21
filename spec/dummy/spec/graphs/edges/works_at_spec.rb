# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edges::WorksAt do
  describe '.new' do
    subject { described_class.new(**attributes) }

    context 'without start nor end nodes' do
      let(:attributes) { { employee_role: 'Quarry Worker' } }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:end_node]).to include "can't be blank"
        expect(subject.errors.messages[:start_node]).to include "can't be blank"
      end
    end

    context 'when using start and end-nodes' do
      let(:attributes) { { employee_role: 'Quarry Worker', start_node: fred, end_node: quarry } }

      context 'when nodes are not persisted' do
        let(:fred) { Nodes::Person.new(first_name: 'Fred', last_name: 'Flintstone', gender: 'male') }
        let(:quarry) { Nodes::Company.new(company_name: 'Rockport Quarry') }

        it { expect(subject).to be_valid }
        it { expect(subject.start_node.id).to be_blank }
        it { expect(subject.end_node.id).to be_blank }
        it { expect(subject.id).to be_blank }
        it '.save' do
          expect(subject.save).to be_truthy
          expect(subject.employee_role).to eq(attributes[:employee_role])
          expect(subject.start_node).to eq(fred)
          expect(subject.end_node).to eq(quarry)
          expect(subject.start_node.id).to be_present
          expect(subject.end_node.id).to be_present
          expect(subject.id).to be_present
          expect(subject.start_node).to be_persisted
          expect(subject.end_node).to be_persisted
          expect(subject).to be_persisted
        end
      end

      context 'when nodes are already persisted' do
        let(:fred) { Nodes::Person.create(first_name: 'Fred', last_name: 'Flintstone', gender: 'male') }
        let(:quarry) { Nodes::Company.create(company_name: 'Rockport Quarry') }

        it { expect(subject).to be_valid }
        it { expect(subject.start_node.id).to be_present }
        it { expect(subject.end_node.id).to be_present }
        it { expect(subject.id).to be_blank }
        it '.save' do
          expect(subject.save).to be_truthy
          expect(subject.id).to be_present
          expect(subject.employee_role).to eq(attributes[:employee_role])
          expect(subject.start_node).to eq(fred)
          expect(subject.end_node).to eq(quarry)
          expect(subject.start_node.id).to be_present
          expect(subject.end_node.id).to be_present
          expect(subject.id).to be_present
          expect(subject.start_node).to be_persisted
          expect(subject.end_node).to be_persisted
          expect(subject).to be_persisted
        end
      end
    end

    context 'when using start_id and end_id' do
      let(:attributes) { { employee_role: 'Quarry Worker', start_id: fred.id, end_id: quarry.id } }

      context 'when nodes are already persisted' do
        let(:fred) { Nodes::Person.create(first_name: 'Fred', last_name: 'Flintstone', gender: 'male') }
        let(:quarry) { Nodes::Company.create(company_name: 'Rockport Quarry') }

        it { expect(subject).to be_valid }
        it { expect(subject.id).to be_blank }
        it { expect(subject).not_to be_persisted }
        it { expect(subject.end_node).to be_persisted }
        it { expect(subject.start_node).to be_persisted }
        it { expect(subject.end_node.id).to be_present }
        it { expect(subject.start_node.id).to be_present }
        it '.save' do
          expect(subject.save).to be_truthy
          expect(subject.id).to be_present
          expect(subject.employee_role).to eq(attributes[:employee_role])
          expect(subject.start_node.id).to be_present
          expect(subject.end_node.id).to be_present
          expect(subject.id).to be_present
          expect(subject.start_node).to be_persisted
          expect(subject.end_node).to be_persisted
          expect(subject).to be_persisted
          # since we are using start_id and end_id, to find the start_node and end_node
          # we need to compare the id of the nodes, not the instance
          expect(subject.start_node.id).to eq(fred.id)
          expect(subject.end_node.id).to eq(quarry.id)
        end
      end
    end
  end

  describe '.create' do
    subject { described_class.new(**attributes) }

    let(:attributes) { { employee_role: 'Quarry Worker', start_node: fred, end_node: quarry } }

    context 'when nodes are not persisted' do
      let(:fred) { Nodes::Person.new(first_name: 'Fred', last_name: 'Flintstone', gender: 'male') }
      let(:quarry) { Nodes::Company.new(company_name: 'Rockport Quarry') }

      it { expect(subject).to be_valid }
      it '' do
        expect(subject.employee_role).to eq(attributes[:employee_role])
        expect(subject.start_node).to eq(fred)
        expect(subject.end_node).to eq(quarry)
        expect(subject.start_node.id).to be_blank
        expect(subject.end_node.id).to be_blank
        expect(subject.id).to be_blank
        expect(subject.start_node).not_to be_persisted
        expect(subject.end_node).not_to be_persisted
        expect(subject).not_to be_persisted
      end
    end

    context 'when nodes are persisted' do
      let(:fred) { Nodes::Person.create(first_name: 'Fred', last_name: 'Flintstone', gender: 'male') }
      let(:quarry) { Nodes::Company.create(company_name: 'Rockport Quarry') }

      it { expect(subject).to be_valid }
      it '' do
        expect(subject.employee_role).to eq(attributes[:employee_role])
        expect(subject.start_node).to eq(fred)
        expect(subject.end_node).to eq(quarry)
        expect(subject.start_node.id).to be_present
        expect(subject.end_node.id).to be_present
        expect(subject.id).to be_blank
        expect(subject.start_node).to be_persisted
        expect(subject.end_node).to be_persisted
        expect(subject).not_to be_persisted
      end
    end
  end
end
