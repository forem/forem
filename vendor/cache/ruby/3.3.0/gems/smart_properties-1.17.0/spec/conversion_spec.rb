require 'spec_helper'

RSpec.describe SmartProperties, 'conversion' do
  context "when defining a class with a property whose converter is an object that responds to #to_proc" do
    subject(:klass) do
      converter = double(to_proc: lambda { |t| content_tag(:p, t.to_s) })
      DummyClass.new do
        property :title, converts: converter

        def content_tag(name, content)
          "<%s>%s</%s>" % [name, content, name]
        end
      end
    end

    context "an instance of this class" do
      subject(:instance) { klass.new }

      it "should convert the property using the proc" do
        instance = klass.new title: 'Chunky Bacon'
        expect(instance.title).to eq("<p>Chunky Bacon</p>")
        expect(instance[:title]).to eq("<p>Chunky Bacon</p>")

        instance.title = "Lorem Ipsum"
        expect(instance.title).to eq("<p>Lorem Ipsum</p>")
        expect(instance[:title]).to eq("<p>Lorem Ipsum</p>")
      end
    end
  end
end
