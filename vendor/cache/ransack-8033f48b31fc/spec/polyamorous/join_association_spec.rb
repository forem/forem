require 'spec_helper'

module Polyamorous
  describe JoinAssociation do

    let(:join_dependency) { new_join_dependency Note, {} }
    let(:reflection) { Note.reflect_on_association(:notable) }
    let(:parent) { join_dependency.send(:join_root) }
    let(:join_association) {
      new_join_association(reflection, parent.children, Article)
    }

    subject { new_join_association(reflection, parent.children, Person) }

    it 'respects polymorphism on equality test' do
      expect(subject).to eq new_join_association(reflection, parent.children, Person)
      expect(subject).not_to eq new_join_association(reflection, parent.children, Article)
    end

    it 'leaves the orginal reflection intact for thread safety' do
      reflection.instance_variable_set(:@klass, Article)
      join_association
      .swapping_reflection_klass(reflection, Person) do |new_reflection|
        expect(new_reflection.options).not_to equal reflection.options
        expect(new_reflection.options).not_to have_key(:polymorphic)
        expect(new_reflection.klass).to eq(Person)
        expect(reflection.klass).to eq(Article)
      end
    end

    it 'sets the polymorphic option to true after initializing' do
      expect(join_association.reflection.options[:polymorphic]).to be true
    end
  end
end
