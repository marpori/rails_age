# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edges::HasJob do
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

  describe 'Queries' do
    let(:betty) { Nodes::Person.create(first_name: 'Betty', last_name: 'Rubble', gender: 'female') }
    let(:wilma) { Nodes::Person.create(first_name: 'Wilma', last_name: 'Flintstone', gender: 'female') }
    let(:news) { Nodes::Company.create(company_name: 'Rockport News') }
    let(:betty_news) { described_class.create(employee_role: 'Reporter', start_node: betty, end_node: news) }
    let(:wilma_news) { described_class.create(employee_role: 'Reporter', start_node: wilma, end_node: news) }

    let(:fred) { Nodes::Person.create(first_name: 'Fred', last_name: 'Flintstone', gender: 'male') }
    let(:barney) { Nodes::Person.create(first_name: 'Barney', last_name: 'Rubble', gender: 'male') }
    let(:mr_slate) { Nodes::Person.create(first_name: 'Mr', last_name: 'Slate', gender: 'male') }
    let(:quarry) { Nodes::Company.create(company_name: 'Rockport Quarry') }
    let(:fred_quarry) { described_class.create(employee_role: 'Quarry Worker', start_node: fred, end_node: quarry) }
    let(:barney_quarry) { described_class.create(employee_role: 'Quarry Worker', start_node: barney, end_node: quarry) }
    let(:mr_slate_quarry) { described_class.create(employee_role: 'Owner', start_node: mr_slate, end_node: quarry) }

    before do
      fred_quarry
      barney_quarry
      mr_slate_quarry
      betty_news
      wilma_news
    end

    describe '.where' do
      context 'single where condition on an edge property' do
        subject { described_class.where(employee_role: 'Quarry Worker') }

        it 'returns all edges with the given employee_role' do
          expect(subject.to_sql)
           .to eq("SELECT * FROM cypher('age_schema', $$ MATCH (start_node)-[find:Edges__HasJob]->(end_node) " \
                  "WHERE find.employee_role = 'Quarry Worker' RETURN find $$) AS (find agtype);")
          expect(subject.all.count).to eq(2)
          expect(subject.all.map(&:id)).to match_array([fred_quarry.id, barney_quarry.id])
        end
      end

      context 'double where (hash) condition on an edge property with start_id' do
        subject { described_class.where(employee_role: 'Quarry Worker').where(start_id: fred.id) }

        it 'returns all edges with the given employee_role' do
          expect(subject.to_sql)
            .to eq("SELECT * FROM cypher('age_schema', $$ MATCH (start_node)-[find:Edges__HasJob]->(end_node) " \
              "WHERE find.employee_role = 'Quarry Worker' AND id(start_node) = #{fred.id} " \
              "RETURN find $$) AS (find agtype);")
          expect(subject.all.count).to eq(1)
          expect(subject.all.map(&:id)).to match_array([fred_quarry.id])
        end
      end

      context 'double where (string) condition on an edge property with start_id' do
        subject { described_class.where("employee_role = ? AND start_id = ?", 'Quarry Worker', fred.id) }

        it 'returns all edges with the given employee_role' do
          expect(subject.to_sql)
            .to eq("SELECT * FROM cypher('age_schema', $$ MATCH (start_node)-[find:Edges__HasJob]->(end_node) " \
              "WHERE find.employee_role = 'Quarry Worker' AND id(start_node) = #{fred.id} " \
              "RETURN find $$) AS (find agtype);")
          expect(subject.all.count).to eq(1)
          expect(subject.all.map(&:id)).to match_array([fred_quarry.id])
        end
      end

      context 'double where (hash) condition on an edge property with start_id' do
        subject { described_class.where(employee_role: 'Quarry Worker').where(start_node: {first_name: fred.first_name}) }

        it 'returns all edges with the given employee_role' do
          expect(subject.to_sql)
            .to eq("SELECT * FROM cypher('age_schema', $$ MATCH (start_node)-[find:Edges__HasJob]->(end_node) " \
              "WHERE find.employee_role = 'Quarry Worker' AND start_node.first_name = '#{fred.first_name}' " \
              "RETURN find $$) AS (find agtype);")
          expect(subject.all.count).to eq(1)
          expect(subject.all.map(&:id)).to match_array([fred_quarry.id])
        end
      end

      context 'double where (string) condition on an edge property with start_id' do
        subject {
          described_class.where(
            "employee_role = ? AND start_node.first_name = ?", 'Quarry Worker', fred.first_name
          )
        }

        it 'returns all edges with the given employee_role' do
          expect(subject.to_sql)
            .to eq("SELECT * FROM cypher('age_schema', $$ MATCH (start_node)-[find:Edges__HasJob]->(end_node) " \
              "WHERE find.employee_role = 'Quarry Worker' AND start_node.first_name = '#{fred.first_name}' " \
              "RETURN find $$) AS (find agtype);")
          expect(subject.all.count).to eq(1)
          expect(subject.all.map(&:id)).to match_array([fred_quarry.id])
        end
      end

      context 'single where condition on a node' do
        subject { described_class.where(end_node: quarry) }

        it 'returns all edges with the given employee_role' do
          expect(subject.to_sql)
            .to eq("SELECT * FROM cypher('age_schema', $$ MATCH (start_node)-[find:Edges__HasJob]->(end_node) " \
                   "WHERE id(end_node) = #{quarry.id} RETURN find $$) AS (find agtype);")
          expect(subject.all.count).to eq(3)
          expect(subject.all.map(&:id)).to match_array([fred_quarry.id, barney_quarry.id, mr_slate_quarry.id])
        end
      end

      context 'with a single where condition on a node attribute' do
        subject { described_class.where(start_node: { last_name: 'Rubble' })}

        it 'returns all edges with the given employee_role' do
          expect(subject.to_sql)
            .to eq("SELECT * FROM cypher('age_schema', $$ " \
                   "MATCH (start_node)-[find:Edges__HasJob]->(end_node) " \
                   "WHERE start_node.last_name = 'Rubble' " \
                   "RETURN find $$) AS (find agtype);")
          expect(subject.all.count).to eq(2)
          ids = subject.all.map(&:id)
          expect(ids).to include(barney_quarry.id)
          expect(ids).to include(betty_news.id)
        end
      end

      context 'with 2 where condition on a node attribute and an edge attribute' do
        subject { described_class.where(start_node: { last_name: 'Rubble' }).where(employee_role: 'Quarry Worker')}

        it 'returns all edges with the given employee_role' do
          expect(subject.to_sql)
            .to eq("SELECT * FROM cypher('age_schema', $$ " \
                   "MATCH (start_node)-[find:Edges__HasJob]->(end_node) " \
                   "WHERE start_node.last_name = 'Rubble' AND find.employee_role = 'Quarry Worker' " \
                   "RETURN find $$) AS (find agtype);")
          expect(subject.all.count).to eq(1)
          ids = subject.all.map(&:id)
          expect(ids).to include(barney_quarry.id)
        end
      end

      context 'multiple where condition on node' do
        subject { described_class.where(end_node: quarry).where(start_node: mr_slate) }

        it 'returns all edges with the given employee_role' do
          expect(subject.all.count).to eq(1)
          expect(subject.all.first.id).to eq(mr_slate_quarry.id)
          expect(subject.to_sql)
            .to eq("SELECT * FROM cypher('age_schema', $$ MATCH (start_node)-[find:Edges__HasJob]->(end_node) " \
                   "WHERE id(end_node) = #{quarry.id} AND id(start_node) = #{mr_slate.id} RETURN find $$) AS (find agtype);")
        end
      end
    end

    describe '.order' do
      context 'single order condition on edge property' do
        subject { described_class.where(end_node: quarry).order(:employee_role) }

        it 'returns all edges with the given employee_role' do
          expect(subject.all.count).to eq(3)
          expect(subject.all.map(&:id).first).to eq(mr_slate_quarry.id)
          expect(subject.to_sql)
            .to eq("SELECT * FROM cypher('age_schema', $$ MATCH (start_node)-[find:Edges__HasJob]->(end_node) " \
                   "WHERE id(end_node) = #{quarry.id} RETURN find ORDER BY find.employee_role $$) AS (find agtype);")
        end
      end

      context 'single order condition with direction' do
        subject { described_class.where(end_node: quarry).order(employee_role: :desc) }

        it 'returns all edges with the given employee_role' do
          expect(subject.all.count).to eq(3)
          expect(subject.all.map(&:id).last).to eq(mr_slate_quarry.id)
          expect(subject.to_sql)
            .to eq("SELECT * FROM cypher('age_schema', $$ MATCH (start_node)-[find:Edges__HasJob]->(end_node) " \
                   "WHERE id(end_node) = #{quarry.id} RETURN find ORDER BY find.employee_role desc $$) AS (find agtype);")
        end
      end

      context 'single order condition on node property with attribute' do
        subject { described_class.where(end_node: quarry).where(start_node: mr_slate).order(employee_role: :desc) }

        it 'returns all edges with the given employee_role' do
          expect(subject.all.count).to eq(1)
          expect(subject.all.first.id).to eq(mr_slate_quarry.id)
          expect(subject.to_sql)
            .to eq("SELECT * FROM cypher('age_schema', $$ MATCH (start_node)-[find:Edges__HasJob]->(end_node) " \
                   "WHERE id(end_node) = #{quarry.id} AND id(start_node) = #{mr_slate.id} RETURN find " \
                   "ORDER BY find.employee_role desc $$) AS (find agtype);")
        end
      end
    end

    describe '.limit' do
      context 'simple limit' do
        subject { described_class.where(end_node: quarry).order(:employee_role).limit(1) }

        it 'returns all edges with the given employee_role' do
          expect(subject.all.count).to eq(1)
          expect(subject.all.map(&:id)).to eq([mr_slate_quarry.id])
          expect(subject.to_sql)
            .to eq("SELECT * FROM cypher('age_schema', $$ MATCH (start_node)-[find:Edges__HasJob]->(end_node) " \
                   "WHERE id(end_node) = #{quarry.id} RETURN find ORDER BY find.employee_role LIMIT 1 $$) AS (find agtype);")
        end
      end

      context 'single wherem order on a nested node property' do
        subject {
          described_class
            .where(employee_role: 'Quarry Worker')
            .order('start_node.first_name desc')
            .limit(1)
        }

        it 'returns the expected worker edge whose first_name is lowest in the alphabet "Fred"' do
          expect(subject.all.count).to eq(1)
          expect(subject.all.first.id).to eq(fred_quarry.id)
          expect(subject.to_sql)
            .to eq("SELECT * FROM cypher('age_schema', $$ MATCH (start_node)-[find:Edges__HasJob]->(end_node) " \
                   "WHERE find.employee_role = 'Quarry Worker' RETURN find ORDER BY start_node.first_name desc LIMIT 1 $$) AS (find agtype);")
        end
      end
    end
  end
end
