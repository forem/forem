# frozen_string_literal: true

require 'spec_helper'

describe 'ActiveRecord behaviors' do
  describe 'a temporary ActiveRecord model created with with_model' do
    context 'that has a named scope' do
      before do
        @regular_model = Class.new ActiveRecord::Base do
          self.table_name = 'regular_models'
          scope :title_is_foo, -> { where(title: 'foo') }
        end

        @regular_model.connection.create_table(@regular_model.table_name, force: true) do |t|
          t.string 'title'
          t.text 'content'
          t.timestamps null: false
        end
      end

      after do
        @regular_model.connection.drop_table(@regular_model.table_name)
      end

      with_model :BlogPost do
        table do |t|
          t.string 'title'
          t.text 'content'
          t.timestamps null: false
        end

        model do
          scope :title_is_foo, -> { where(title: 'foo') }
        end
      end

      describe 'the named scope' do
        it 'works like a regular named scope' do
          included = @regular_model.create!(title: 'foo', content: 'Include me!')
          @regular_model.create!(title: 'bar', content: 'Include me!')

          expect(@regular_model.title_is_foo).to eq [included]

          included = BlogPost.create!(title: 'foo', content: 'Include me!')
          BlogPost.create!(title: 'bar', content: 'Include me!')

          expect(BlogPost.title_is_foo).to eq [included]
        end
      end
    end

    context 'that has a polymorphic belongs_to' do
      before do
        animal = Class.new ActiveRecord::Base do
          has_many :tea_cups, as: :pet
        end
        stub_const 'Animal', animal
      end

      with_model :TeaCup do
        table do |t|
          t.belongs_to :pet, polymorphic: true, index: false
        end
        model do
          belongs_to :pet, polymorphic: true
        end
      end

      with_table :animals

      with_model :StuffedAnimal do
        model do
          has_many :tea_cups, as: :pet
        end
      end

      describe 'the polymorphic belongs_to' do
        it 'works like a regular polymorphic belongs_to' do
          animal = Animal.create!
          stuffed_animal = StuffedAnimal.create!

          tea_cup_for_animal = TeaCup.create!(pet: animal)
          expect(tea_cup_for_animal.pet_type).to eq 'Animal'
          expect(animal.tea_cups).to include(tea_cup_for_animal)

          tea_cup_for_stuffed_animal = TeaCup.create!(pet: stuffed_animal)
          expect(tea_cup_for_stuffed_animal.pet_type).to eq 'StuffedAnimal'
          expect(stuffed_animal.tea_cups).to include(tea_cup_for_stuffed_animal)
        end
      end
    end
  end

  context 'with an association' do
    with_model :Province do
      table do |t|
        t.belongs_to :country
      end
      model do
        belongs_to :country
      end
    end

    with_model :Country

    context 'in earlier examples' do
      it 'works as normal' do
        expect { Province.create!(country: Country.create!) }.not_to raise_error
      end
    end

    context 'in later examples' do
      it "does not hold a reference to earlier example groups' classes" do
        expect(Province.reflect_on_association(:country).klass).to eq Country
      end
    end
  end
end
