# frozen_string_literal: true

# rubocop:disable Lint/ConstantDefinitionInBlock

require 'spec_helper'

RSpec.describe 'AmazingPrint/MongoMapper', skip: -> { !ExtVerifier.has_mongo_mapper? }.call do
  if ExtVerifier.has_mongo_mapper?
    before :all do
      class MongoUser
        include MongoMapper::Document

        key :first_name, String
        key :last_name, String
      end
    end

    after :all do
      Object.instance_eval { remove_const :MongoUser }
      Object.instance_eval { remove_const :Chamelion }
    end
  end

  before do
    @ap = AmazingPrint::Inspector.new(plain: true, sort_keys: true)
  end

  describe 'with the raw option set to true' do
    # before { @ap.options[:raw] = true }
    before { @ap = AmazingPrint::Inspector.new(plain: true, sort_keys: true, raw: true) }

    it 'prints class instance' do
      user = MongoUser.new(first_name: 'Al', last_name: 'Capone')

      out = @ap.send(:awesome, user)
               .gsub(/#<Proc:.+?>/, 'amazing_print_PROC_STUB')
               .gsub(/BSON::ObjectId\('[\da-f]+?'\)/, "BSON::ObjectId('123456789')")

      str = if MongoMapper::Version >= '0.13'
              <<~EOS.strip
                #<MongoUser:placeholder_id
                    @__mm_default_keys = [
                        [0] #<MongoMapper::Plugins::Keys::Key:placeholder_id
                            @dynamic = false,
                            @embeddable = false,
                            @has_default = true,
                            @is_id = true,
                            @typecast = nil,
                            attr_accessor :accessors = [],
                            attr_accessor :default = amazing_print_PROC_STUB,
                            attr_accessor :ivar = :@_id,
                            attr_accessor :name = "_id",
                            attr_accessor :options = {
                                :default => amazing_print_PROC_STUB
                            },
                            attr_accessor :type = ObjectId < Object
                        >
                    ],
                    @__mm_keys = {
                               "_id" => #<MongoMapper::Plugins::Keys::Key:placeholder_id
                            @dynamic = false,
                            @embeddable = false,
                            @has_default = true,
                            @is_id = true,
                            @typecast = nil,
                            attr_accessor :accessors = [],
                            attr_accessor :default = amazing_print_PROC_STUB,
                            attr_accessor :ivar = :@_id,
                            attr_accessor :name = "_id",
                            attr_accessor :options = {
                                :default => amazing_print_PROC_STUB
                            },
                            attr_accessor :type = ObjectId < Object
                        >,
                        "first_name" => #<MongoMapper::Plugins::Keys::Key:placeholder_id
                            @dynamic = false,
                            @embeddable = false,
                            @has_default = false,
                            @is_id = false,
                            @typecast = nil,
                            attr_accessor :accessors = [],
                            attr_accessor :ivar = :@first_name,
                            attr_accessor :name = "first_name",
                            attr_accessor :options = {},
                            attr_accessor :type = String < Object
                        >,
                         "last_name" => #<MongoMapper::Plugins::Keys::Key:placeholder_id
                            @dynamic = false,
                            @embeddable = false,
                            @has_default = false,
                            @is_id = false,
                            @typecast = nil,
                            attr_accessor :accessors = [],
                            attr_accessor :ivar = :@last_name,
                            attr_accessor :name = "last_name",
                            attr_accessor :options = {},
                            attr_accessor :type = String < Object
                        >
                    },
                    @__mm_pre_cast = {
                        "first_name" => "Al",
                         "last_name" => "Capone"
                    },
                    @_dynamic_attributes = {},
                    @_new = true,
                    attr_accessor :_id = BSON::ObjectId('123456789'),
                    attr_accessor :attributes = nil,
                    attr_accessor :first_name = "Al",
                    attr_accessor :last_name = "Capone",
                    attr_reader :changed_attributes = {
                        "first_name" => nil,
                         "last_name" => nil
                    }
                >
              EOS
            else
              <<~EOS.strip
                #<MongoUser:placeholder_id
                    @_new = true,
                    attr_accessor :first_name = "Al",
                    attr_accessor :last_name = "Capone",
                    attr_reader :changed_attributes = {
                        "first_name" => nil,
                         "last_name" => nil
                    },
                    attr_reader :first_name_before_type_cast = "Al",
                    attr_reader :last_name_before_type_cast = "Capone"
                >
              EOS
            end
      expect(out).to be_similar_to(str)
    end

    it 'prints the class' do
      expect(@ap.send(:awesome, MongoUser)).to eq <<~EOS.strip
        class MongoUser < Object {
                   "_id" => :object_id,
            "first_name" => :string,
             "last_name" => :string
        }
      EOS
    end

    it 'prints the class when type is undefined' do
      class Chamelion
        include MongoMapper::Document
        key :last_attribute
      end

      expect(@ap.send(:awesome, Chamelion)).to eq <<~EOS.strip
        class Chamelion < Object {
                       "_id" => :object_id,
            "last_attribute" => :undefined
        }
      EOS
    end
  end

  describe 'with associations' do
    if ExtVerifier.has_mongo_mapper?
      before :all do
        class Child
          include MongoMapper::EmbeddedDocument
          key :data
        end

        class Sibling
          include MongoMapper::Document
          key :title
        end

        class Parent
          include MongoMapper::Document
          key :name

          one :child
          one :sibling
        end
      end
    end

    describe 'with show associations turned off (default)' do
      it 'renders the class as normal' do
        expect(@ap.send(:awesome, Parent)).to eq <<~EOS.strip
          class Parent < Object {
               "_id" => :object_id,
              "name" => :undefined
          }
        EOS
      end

      it 'renders an instance as normal' do
        parent = Parent.new(name: 'test')
        out = @ap.send(:awesome, parent)
        str = <<~EOS.strip
          #<Parent:placeholder_id> {
               "_id" => placeholder_bson_id,
              "name" => "test"
          }
        EOS
        expect(out).to be_similar_to(str)
      end
    end

    describe 'with show associations turned on and inline embedded turned off' do
      before do
        @ap = AmazingPrint::Inspector.new(plain: true, mongo_mapper: { show_associations: true })
      end

      it 'renders the class with associations shown' do
        expect(@ap.send(:awesome, Parent)).to eq <<~EOS.strip
          class Parent < Object {
                  "_id" => :object_id,
                 "name" => :undefined,
                "child" => embeds one Child,
              "sibling" => one Sibling
          }
        EOS
      end

      it 'renders an instance with associations shown' do
        parent = Parent.new(name: 'test')
        out = @ap.send(:awesome, parent)
        str = <<~EOS.strip
          #<Parent:placeholder_id> {
                  "_id" => placeholder_bson_id,
                 "name" => "test",
                "child" => embeds one Child,
              "sibling" => one Sibling
          }
        EOS
        expect(out).to be_similar_to(str)
      end
    end

    describe 'with show associations turned on and inline embedded turned on' do
      before do
        @ap = AmazingPrint::Inspector.new plain: true,
                                          mongo_mapper: {
                                            show_associations: true,
                                            inline_embedded: true
                                          }
      end

      it 'renders an instance with associations shown and embeds there' do
        parent = Parent.new(name: 'test', child: Child.new(data: 5))
        out = @ap.send(:awesome, parent)
        str = <<~EOS.strip
          #<Parent:placeholder_id> {
                  "_id" => placeholder_bson_id,
                 "name" => "test",
                "child" => embedded #<Child:placeholder_id> {
                   "_id" => placeholder_bson_id,
                  "data" => 5
              },
              "sibling" => one Sibling
          }
        EOS
        expect(out).to be_similar_to(str)
      end
    end
  end
end

# rubocop:enable Lint/ConstantDefinitionInBlock
