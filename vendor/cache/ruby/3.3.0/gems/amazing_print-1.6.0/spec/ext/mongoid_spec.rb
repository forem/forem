# frozen_string_literal: true

# rubocop:disable Lint/ConstantDefinitionInBlock

require 'spec_helper'

RSpec.describe 'AmazingPrint/Mongoid', skip: -> { !ExtVerifier.has_mongoid? }.call do
  before do
    @ap = AmazingPrint::Inspector.new plain: true, sort_keys: true
  end

  describe 'Document' do
    if ExtVerifier.has_mongoid?
      before :all do
        class MongoUser
          include Mongoid::Document

          field :first_name, type: String
          field :last_name,  type: String
        end
      end

      after :all do
        Object.instance_eval { remove_const :MongoUser }
        Object.instance_eval { remove_const :Chamelion }
      end
    end

    it 'prints class instance' do
      user = MongoUser.new first_name: 'Al', last_name: 'Capone'
      out = @ap.send :awesome, user

      object_id = user.id.inspect
      str = <<~EOS.strip
        #<MongoUser:placeholder_id> {
                   :_id => #{object_id},
            :first_name => "Al",
             :last_name => "Capone"
        }
      EOS
      expect(out).to be_similar_to(str, { skip_bson: true })
    end

    it 'prints the class' do
      class_spec = <<~EOS.strip
        class MongoUser < Object {
                   :_id => :"bson/object_id",
            :first_name => :string,
             :last_name => :string
        }
      EOS

      expect(@ap.send(:awesome, MongoUser)).to eq class_spec
    end

    it 'prints the class when type is undefined' do
      class Chamelion
        include Mongoid::Document
        field :last_attribute
      end

      class_spec = <<~EOS.strip
        class Chamelion < Object {
                       :_id => :"bson/object_id",
            :last_attribute => :object
        }
      EOS

      expect(@ap.send(:awesome, Chamelion)).to eq class_spec
    end
  end

  describe 'Document with aliased fields' do
    if ExtVerifier.has_mongoid?
      before :all do
        class MongoUser
          include Mongoid::Document

          field :fn, as: :first_name, type: String
          field :ln, as: :last_name,  type: String
        end
      end

      after :all do
        Object.instance_eval { remove_const :MongoUser }
        Object.instance_eval { remove_const :Chamelion }
      end
    end

    it 'prints class instance' do
      user = MongoUser.new first_name: 'Al', last_name: 'Capone'
      out = @ap.send :awesome, user

      object_id = user.id.inspect
      str = <<~EOS.strip
        #<MongoUser:placeholder_id> {
                         :_id => #{object_id},
            :"first_name(fn)" => "Al",
             :"last_name(ln)" => "Capone"
        }
      EOS
      expect(out).to be_similar_to(str, { skip_bson: true })
    end

    it 'prints the class' do
      class_spec = <<~EOS.strip
        class MongoUser < Object {
                         :_id => :"bson/object_id",
            :"first_name(fn)" => :string,
             :"last_name(ln)" => :string
        }
      EOS

      expect(@ap.send(:awesome, MongoUser)).to eq class_spec
    end

    it 'prints the class when type is undefined' do
      class Chamelion
        include Mongoid::Document
        field :la, as: :last_attribute
      end

      class_spec = <<~EOS.strip
        class Chamelion < Object {
                             :_id => :"bson/object_id",
            :"last_attribute(la)" => :object
        }
      EOS

      expect(@ap.send(:awesome, Chamelion)).to eq class_spec
    end
  end
end

# rubocop:enable Lint/ConstantDefinitionInBlock
