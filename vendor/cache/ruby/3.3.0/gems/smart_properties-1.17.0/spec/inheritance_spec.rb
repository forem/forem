require 'spec_helper'

RSpec.describe SmartProperties, 'intheritance' do
  context 'when used to build a class that has a required property with no default called :text whose getter is overriden' do
    subject(:klass) do
      DummyClass.new do
        property :text, required: true
        def text; "<em>#{super}</em>"; end
      end
    end

    specify "an instance of this class should raise an error during initilization if no value for :text has been specified" do
      expect { klass.new }.to raise_error(SmartProperties::InitializationError)
    end
  end

  context 'when modeling the following class hiearchy: Base > Section > SectionWithSubtitle' do
    let!(:base) do
      Class.new do
        attr_reader :content, :options
        def initialize(content = nil, options = {})
          @content = content
          @options = options
        end
      end
    end
    let!(:section) { DummyClass.new(base) { property :title } }
    let!(:subsection) { DummyClass.new(section) { property :subtitle } }
    let!(:subsubsection) { DummyClass.new(subsection) { property :subsubtitle } }

    context 'the base class' do
      it('should not respond to #properties') { expect(base).to_not respond_to(:properties) }
    end

    context 'the section class' do
      it('should respond to #properties') { expect(section).to respond_to(:properties) }

      it "should expose the names of the properties through its property collection" do
        expect(section.properties.keys).to eq([:title])
      end

      it "should expose the the properties through its property collection" do
        properties = subsection.properties.values
        expect(properties.first).to be_kind_of(SmartProperties::Property)
        expect(properties.first.name).to eq(:title)
      end

      context 'an instance of this class' do
        subject { section.new }
        it { is_expected.to have_smart_property(:title) }
        it { is_expected.to_not have_smart_property(:subtitle) }

        it 'should forward keyword arguments that do not correspond to a property to the super class constructor' do
          instance = section.new('some content', answer: 42)
          expect(instance.options).to eq({answer: 42})
        end
      end

      context 'an instance of this class when initialized with content' do
        subject(:instance) { section.new('some content') }
        it('should have content') { expect(instance.content).to eq('some content') }
      end
    end

    context 'the subsectionclass' do
      it('should respond to #properties') { expect(subsection).to respond_to(:properties) }

      it "should expose the names of the properties through its property collection" do
        expect(subsection.properties.keys).to eq([:title, :subtitle])
      end

      it "should expose the the properties through its property collection" do
        properties = subsection.properties.values
        expect(properties.first).to be_kind_of(SmartProperties::Property)
        expect(properties.first.name).to eq(:title)

        expect(properties.last).to be_kind_of(SmartProperties::Property)
        expect(properties.last.name).to eq(:subtitle)
      end

      context 'an instance of this class' do
        subject(:instance) { subsection.new }
        it { is_expected.to have_smart_property(:title) }
        it { is_expected.to have_smart_property(:subtitle) }

        it 'should have content, a title, and a subtile when initialized with these parameters' do
          instance = subsection.new('some content', title: 'some title', subtitle: 'some subtitle')
          expect(instance.content).to eq('some content')
          expect(instance.title).to eq('some title')
          expect(instance.subtitle).to eq('some subtitle')

          instance = subsection.new('some content') do |s|
            s.title, s.subtitle = 'some title', 'some subtitle'
          end
          expect(instance.content).to eq('some content')
          expect(instance.title).to eq('some title')
          expect(instance.subtitle).to eq('some subtitle')
        end

        it 'should forward keyword arguments that do not correspond to a property to the super class constructor' do
          instance = subsection.new('some content', answer: 42)
          expect(instance.options).to eq({answer: 42})
        end
      end
    end

    context 'the subsubsectionclass' do
      it "should expose the names of the properties through its property collection" do
        expect(subsubsection.properties.keys).to eq([:title, :subtitle, :subsubtitle])
      end

      it "should expose the the properties through its property collection" do
        properties = subsubsection.properties.values

        expect(properties[0]).to be_kind_of(SmartProperties::Property)
        expect(properties[0].name).to eq(:title)

        expect(properties[1]).to be_kind_of(SmartProperties::Property)
        expect(properties[1].name).to eq(:subtitle)

        expect(properties[2]).to be_kind_of(SmartProperties::Property)
        expect(properties[2].name).to eq(:subsubtitle)
      end

      context 'an instance of this class' do
        subject(:instance) { subsubsection.new }
        it { is_expected.to have_smart_property(:title) }
        it { is_expected.to have_smart_property(:subtitle) }
        it { is_expected.to have_smart_property(:subsubtitle) }

        it 'should have content, a title, and a subtile when initialized with these parameters' do
          instance = subsubsection.new('some content', title: 'some title', subtitle: 'some subtitle', subsubtitle: 'some subsubtitle')
          expect(instance.content).to eq('some content')
          expect(instance.title).to eq('some title')
          expect(instance.subtitle).to eq('some subtitle')
          expect(instance.subsubtitle).to eq('some subsubtitle')

          instance = subsubsection.new('some content') do |s|
            s.title, s.subtitle, s.subsubtitle = 'some title', 'some subtitle', 'some subsubtitle'
          end
          expect(instance.content).to eq('some content')
          expect(instance.title).to eq('some title')
          expect(instance.subtitle).to eq('some subtitle')
          expect(instance.subsubtitle).to eq('some subsubtitle')
        end

        it 'should not accidentally forward attributes as options because the keys where strings' do
          attributes = {'title' => 'some title', 'subtitle' => 'some subtitle', 'subsubtitle' => "some subsubtitle", "answer" => 42}
          instance = subsubsection.new('some content', attributes)
          expect(instance.content).to eq('some content')
          expect(instance.title).to eq('some title')
          expect(instance.subtitle).to eq('some subtitle')
          expect(instance.subsubtitle).to eq('some subsubtitle')
          expect(instance.options).to eq({"answer" => 42})
        end

        it 'should forward keyword arguments that do not correspond to a property to the super class constructor' do
          instance = subsubsection.new('some content', answer: 42)
          expect(instance.options).to eq({answer: 42})
        end
      end
    end

    context 'when the section class is extended with a property at runtime' do
      before { section.send(:property, :type) }

      context 'the section class' do
        subject { section }
        it { is_expected.to have_smart_property(:type) }

        it 'should have content, a title, and a type when initialized with these parameters' do
          instance = subsection.new('some content', title: 'some title', type: 'important')
          expect(instance.content).to eq('some content')
          expect(instance.title).to eq('some title')
          expect(instance.type).to eq('important')

          instance = subsection.new('some content') do |s|
            s.title, s.type = 'some title', 'important'
          end
          expect(instance.content).to eq('some content')
          expect(instance.title).to eq('some title')
          expect(instance.type).to eq('important')
        end
      end

      context 'the subsection class' do
        subject { subsection }
        it { is_expected.to have_smart_property(:type) }

        it 'should have content, a title, a subtitle, and a type when initialized with these parameters' do
          instance = subsection.new('some content', title: 'some title', subtitle: 'some subtitle', type: 'important')
          expect(instance.content).to eq('some content')
          expect(instance.title).to eq('some title')
          expect(instance.subtitle).to eq('some subtitle')
          expect(instance.type).to eq('important')

          instance = subsection.new('some content') do |s|
            s.title, s.subtitle, s.type = 'some title', 'some subtitle', 'important'
          end
          expect(instance.content).to eq('some content')
          expect(instance.title).to eq('some title')
          expect(instance.subtitle).to eq('some subtitle')
          expect(instance.type).to eq('important')
        end
      end
    end

    context 'when the section class overrides the getter of the title property and uses super to retrieve the property\'s original value' do
      before do
        section.class_eval do
          def title; super.to_s.upcase; end
        end
      end

      specify 'an instance of the section class should transform the value as defined in the overridden getter' do
        instance = section.new(title: 'some title')
        expect(instance.title).to eq('SOME TITLE')
        expect(instance[:title]).to eq('SOME TITLE')
      end

      specify 'an instance of the subsection class should transform the value as defined in the overridden getter in the superclass' do
        instance = subsection.new(title: 'some title')
        expect(instance.title).to eq('SOME TITLE')
        expect(instance[:title]).to eq('SOME TITLE')
      end
    end
  end

  context "through modules" do
    let(:m) do
      m = Module.new do
        include SmartProperties
        property :m, default: 1
      end
    end

    let(:n) do
      n = Module.new do
        include SmartProperties
        property :n, default: 2
      end
    end

    it "is supported" do
      n = self.n
      m = self.m
      o = Module.new {}

      klass = Class.new do
        include m
        include o
        include n
      end

      n.module_eval do
        property :p, default: 3
      end

      instance = klass.new

      expect(instance.m).to eq(1)
      expect(instance.n).to eq(2)
      expect(instance.p).to eq(3)

      expect { klass.new(m: 4, n: 5, p: 6) }.to_not raise_error
    end

    it "always extends module with ModuleMethods but never classes" do
      n = self.n

      klass = Class.new do
        include n
      end

      module_singleton_class_ancestors = n.singleton_class.ancestors

      expect(module_singleton_class_ancestors).to include(SmartProperties::ClassMethods)
      expect(module_singleton_class_ancestors).to include(SmartProperties::ModuleMethods)

      singleton_class_ancestors = klass.singleton_class.ancestors

      expect(singleton_class_ancestors).to include(SmartProperties::ClassMethods)
      expect(singleton_class_ancestors).not_to include(SmartProperties::ModuleMethods)
    end

    it "yields properly ordered properties – child properties have higher precedence than parent properties" do
      n = self.n
      m = self.m

      parent = Class.new do
        include m
        include n
      end
      expect(parent.new.m).to eq(1)

      child = Class.new(parent) do
        property :m, default: 0
      end
      expect(child.new.m).to eq(0)

      grandchild = Class.new(child)
      expect(grandchild.new.m).to eq(0)

      grandgrandchild = Class.new(grandchild) do
        property :m, default: 1000
      end
      expect(grandgrandchild.new.m).to eq(1000)
    end
  end
end
