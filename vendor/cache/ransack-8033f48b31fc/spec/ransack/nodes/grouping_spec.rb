require 'spec_helper'

module Ransack
  module Nodes
    describe Grouping do

      before do
        @g = 1
      end

      let(:context) { Context.for(Person) }

      subject { described_class.new(context) }

      describe '#attribute_method?' do
        context 'for attributes of the context' do
          it 'is true' do
            expect(subject.attribute_method?('name')).to be true
          end

          context "when the attribute contains '_and_'" do
            it 'is true' do
              expect(subject.attribute_method?('terms_and_conditions')).to be true
            end
          end

          context "when the attribute contains '_or_'" do
            it 'is true' do
              expect(subject.attribute_method?('true_or_false')).to be true
            end
          end

          context "when the attribute ends with '_start'" do
            it 'is true' do
              expect(subject.attribute_method?('life_start')).to be true
            end
          end

          context "when the attribute ends with '_end'" do
            it 'is true' do
              expect(subject.attribute_method?('stop_end')).to be true
            end
          end
        end

        context 'for unknown attributes' do
          it 'is false' do
            expect(subject.attribute_method?('not_an_attribute')).to be false
          end
        end
      end

      describe '#conditions=' do
        context 'when conditions are identical' do
          let(:conditions) do
            {
              '0' => {
                'a' => { '0'=> { 'name' => 'name', 'ransacker_args' => '' } },
                'p' => 'cont',
                'v' => { '0' => { 'value' => 'John' } }
              },
              '1' => {
                'a' => { '0' => { 'name' => 'name', 'ransacker_args' => '' } },
                'p' => 'cont',
                'v' => { '0' => { 'value' => 'John' } }
              }
            }
          end
          before { subject.conditions = conditions }

          it 'expect duplicates to be removed' do
            expect(subject.conditions.count).to eq 1
          end
        end

        context 'when conditions differ only by ransacker_args' do
          let(:conditions) do
            {
              '0' => {
                'a' => {
                  '0' => {
                    'name' => 'with_arguments',
                    'ransacker_args' => [1,2]
                  }
                },
                'p' => 'eq',
                'v' => { '0' => { 'value' => '10' } }
              },
              '1' => {
                'a' => {
                  '0' => {
                    'name' => 'with_arguments',
                    'ransacker_args' => [3,4]
                  }
                },
                'p' => 'eq',
                'v' => { '0' => { 'value' => '10' } }
              }
            }
          end
          before { subject.conditions = conditions }

          it 'expect them to be parsed as different and not as duplicates' do
            expect(subject.conditions.count).to eq 2
          end
        end
      end

    end
  end
end
