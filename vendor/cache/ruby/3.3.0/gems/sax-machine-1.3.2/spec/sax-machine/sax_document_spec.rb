require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "SAXMachine" do
  describe "element" do
    describe "when parsing a single element" do
      before do
        @klass = Class.new do
          include SAXMachine
          element :title
          ancestor :body
          value :something, required: false
          attribute :anything, required: true
        end
      end

      it "provides mass assignment through initialize method" do
        document = @klass.new(title: "Title")
        expect(document.title).to eq("Title")
      end

      it "provides an accessor" do
        document = @klass.new
        document.title = "Title"
        expect(document.title).to eq("Title")
      end

      it "does not overwrites the getter is there is already one present" do
        @klass = Class.new do
          def title
            "#{@title} ***"
          end

          include SAXMachine
          element :title
        end

        document = @klass.new
        document.title = "Title"
        expect(document.title).to eq("Title ***")
      end

      it "does not overwrites the setter if there is already one present" do
        @klass = Class.new do
          def title=(val)
            @title = "#{val} **"
          end

          include SAXMachine
          element :title
        end

        document = @klass.new
        document.title = "Title"
        expect(document.title).to eq("Title **")
      end

      it "does not overwrites the accessor when the element is not present" do
        document = @klass.new
        document.title = "Title"
        document.parse("<foo></foo>")
        expect(document.title).to eq("Title")
      end

      it "overwrites the value when the element is present" do
        document = @klass.new
        document.title = "Old title"
        document.parse("<title>New title</title>")
        expect(document.title).to eq("New title")
      end

      it "saves the element text into an accessor" do
        document = @klass.parse("<title>My Title</title>")
        expect(document.title).to eq("My Title")
      end

      it "keeps the document encoding for elements" do
        data = "<title>My Title</title>"
        data.encode!("utf-8")

        document = @klass.parse(data)
        expect(document.title.encoding).to eq(data.encoding)
      end

      it "saves cdata into an accessor" do
        document = @klass.parse("<title><![CDATA[A Title]]></title>")
        expect(document.title).to eq("A Title")
      end

      it "saves the element text into an accessor when there are multiple elements" do
        document = @klass.parse("<xml><title>My Title</title><foo>bar</foo></xml>")
        expect(document.title).to eq("My Title")
      end

      it "saves the first element text when there are multiple of the same element" do
        document = @klass.parse("<xml><title>My Title</title><title>bar</title></xml>")
        expect(document.title).to eq("My Title")
      end

      describe "the introspection" do
        it "allows to get column names" do
          expect(@klass.column_names).to match_array([:title])
        end

        it "allows to get elements" do
          expect(@klass.sax_config.top_level_elements.values.flatten.map(&:to_s)).to \
            match_array(["name: title dataclass:  setter: title= required:  value:  as:title collection:  with: {}"])
        end

        it "allows to get ancestors" do
          expect(@klass.sax_config.ancestors.map(&:column)).to \
            match_array([:body])
        end

        it "allows to get values" do
          expect(@klass.sax_config.top_level_element_value.map(&:column)).to \
            match_array([:something])
          expect(@klass.sax_config.top_level_element_value.map(&:required?)).to \
            match_array([false])
        end

        it "allows to get attributes" do
          expect(@klass.sax_config.top_level_attributes.map(&:column)).to \
            match_array([:anything])
          expect(@klass.sax_config.top_level_attributes.map(&:required?)).to \
            match_array([true])
          expect(@klass.sax_config.top_level_attributes.map(&:collection?)).to \
            match_array([false])
        end
      end

      describe "the class attribute" do
        before(:each) do
          @klass = Class.new do
            include SAXMachine
            element :date, class: DateTime
          end

          @document = @klass.new
          @document.date = Time.now.iso8601
        end

        it "is available" do
          expect(@klass.data_class(:date)).to eq(DateTime)
        end

        describe "string" do
          before do
            class TestString
              include SAXMachine
              element :number, class: String
            end

            class TestStringAttribute
              include SAXMachine
              attribute :sub_number, class: String
            end

            class TestStringWithAttribute
              include SAXMachine
              element :number, class: TestStringAttribute
            end
          end

          it "is handled in an element" do
            document = TestString.parse("<number>5.5</number>")
            expect(document.number).to eq("5.5")
          end

          it "is handled in an attribute" do
            document = TestStringWithAttribute.parse("<number sub_number='5.5'></number>")
            expect(document.number.sub_number).to eq("5.5")
          end
        end

        describe "integer" do
          before do
            class TestInteger
              include SAXMachine
              element :number, class: Integer
            end

            class TestIntegerAttribute
              include SAXMachine
              attribute :sub_number, class: Integer
            end

            class TestIntegerWithAttribute
              include SAXMachine
              element :number, class: TestIntegerAttribute
            end
          end

          it "is handled in an element" do
            document = TestInteger.parse("<number>5</number>")
            expect(document.number).to eq(5)
          end

          it "is handled in an attribute" do
            document = TestIntegerWithAttribute.parse("<number sub_number='5'></number>")
            expect(document.number.sub_number).to eq(5)
          end
        end

        describe "float" do
          before do
            class TestFloat
              include SAXMachine
              element :number, class: Float
            end

            class TestFloatAttribute
              include SAXMachine
              attribute :sub_number, class: Float
            end

            class TestFloatWithAttribute
              include SAXMachine
              element :number, class: TestFloatAttribute
            end
          end

          it "is handled in an element with '.' delimiter" do
            document = TestFloat.parse("<number>5.5</number>")
            expect(document.number).to eq(5.5)
          end

          it "is handled in an element with ',' delimiter" do
            document = TestFloat.parse("<number>5,5</number>")
            expect(document.number).to eq(5.5)
          end

          it "is handled in an attribute" do
            document = TestFloatWithAttribute.parse("<number sub_number='5.5'>5.5</number>")
            expect(document.number.sub_number).to eq(5.5)
          end
        end

        describe "symbol" do
          before do
            class TestSymbol
              include SAXMachine
              element :symbol, class: Symbol
            end

            class TestSymbolAttribute
              include SAXMachine
              attribute :sub_symbol, class: Symbol
            end

            class TestSymbolWithAttribute
              include SAXMachine
              element :symbol, class: TestSymbolAttribute
            end
          end

          it "is handled in an element" do
            document = TestSymbol.parse("<symbol>MY_SYMBOL_VALUE</symbol>")
            expect(document.symbol).to eq(:my_symbol_value)
          end

          it "is handled in an attribute" do
            document = TestSymbolWithAttribute.parse("<symbol sub_symbol='MY_SYMBOL_VALUE'></symbol>")
            expect(document.symbol.sub_symbol).to eq(:my_symbol_value)
          end
        end

        describe "time" do
          before do
            class TestTime
              include SAXMachine
              element :time, class: Time
            end

            class TestTimeAttribute
              include SAXMachine
              attribute :sub_time, class: Time
            end

            class TestTimeWithAttribute
              include SAXMachine
              element :time, class: TestTimeAttribute
            end
          end

          it "is handled in an element" do
            document = TestTime.parse("<time>1994-02-04T06:20:00Z</time>")
            expect(document.time).to eq(Time.utc(1994, 2, 4, 6, 20, 0, 0))
          end

          it "is handled in an attribute" do
            document = TestTimeWithAttribute.parse("<time sub_time='1994-02-04T06:20:00Z'>1994-02-04T06:20:00Z</time>")
            expect(document.time.sub_time).to eq(Time.utc(1994, 2, 4, 6, 20, 0, 0))
          end
        end
      end

      describe "the default attribute" do
        it "is available" do
          @klass = Class.new do
            include SAXMachine
            element :number, class: Integer, default: 0
          end

          document = @klass.parse("<no>number</no>")
          expect(document.number).to eq(0)

          document = @klass.parse("<number></number>")
          expect(document.number).to eq(0)
        end

        it "can be a Boolean" do
          @klass = Class.new do
            include SAXMachine
            element(:bool, default: false) { |v| !!v }
          end

          document = @klass.parse("<no>bool</no>")
          expect(document.bool).to be false

          document = @klass.parse("<bool></bool>")
          expect(document.bool).to be false

          document = @klass.parse("<bool>1</bool>")
          expect(document.bool).to be true
        end
      end

      describe "the required attribute" do
        it "is available" do
          @klass = Class.new do
            include SAXMachine
            element :date, required: true
          end
          expect(@klass.required?(:date)).to be_truthy
        end
      end

      describe "the block" do
        before do
          class ElementBlockParser
            include SAXMachine

            ancestor :parent do |parent|
              parent.class.to_s
            end

            value :text do |text|
              text.downcase
            end
          end

          class BlockParser
            include SAXMachine

            element :title do |title|
              "#{title}!!!"
            end

            element :scope do |scope|
              "#{title} #{scope}"
            end

            attribute :id do |id|
              id.to_i
            end

            element :nested, class: ElementBlockParser
            elements :message, as: :messages do |message|
              "#{message}!"
            end
          end
        end

        it "has instance as a block context" do
          document = BlockParser.parse("<root><title>SAX</title><scope>something</scope></root>")
          expect(document.scope).to eq("SAX!!! something")
        end

        it "uses block for element" do
          document = BlockParser.parse("<title>SAX</title>")
          expect(document.title).to eq("SAX!!!")
        end

        it 'uses block for attribute' do
          document = BlockParser.parse("<title id='345'>SAX</title>")
          expect(document.id).to eq(345)
        end

        it "uses block for value" do
          document = BlockParser.parse("<title><nested>tEst</nested></title>")
          expect(document.nested.text).to eq("test")
        end

        it "uses block for ancestor" do
          document = BlockParser.parse("<title><nested>SAX</nested></title>")
          expect(document.nested.parent).to eq("BlockParser")
        end

        it "uses block for elements" do
          document = BlockParser.parse("<title><message>hi</message><message>world</message></title>")
          expect(document.messages).to eq(["hi!", "world!"])
        end
      end
    end

    describe "when parsing multiple elements" do
      before do
        @klass = Class.new do
          include SAXMachine
          element :title
          element :name
        end
      end

      it "saves the element text for a second tag" do
        document = @klass.parse("<xml><title>My Title</title><name>Paul</name></xml>")
        expect(document.name).to eq("Paul")
        expect(document.title).to eq("My Title")
      end

      it "does not overwrites the getter is there is already one present" do
        @klass = Class.new do
          def items
            []
          end

          include SAXMachine
          elements :items
        end

        document = @klass.new
        document.items = [1, 2, 3, 4]
        expect(document.items).to eq([])
      end

      it "does not overwrites the setter if there is already one present" do
        @klass = Class.new do
          def items=(val)
            @items = [1, *val]
          end

          include SAXMachine
          elements :items
        end

        document = @klass.new
        document.items = [2, 3]
        expect(document.items).to eq([1, 2, 3])
      end
    end

    describe "when using options for parsing elements" do
      describe "using the 'as' option" do
        before do
          @klass = Class.new do
            include SAXMachine
            element :description, as: :summary
          end
        end

        it "provides an accessor using the 'as' name" do
          document = @klass.new
          document.summary = "a small summary"
          expect(document.summary).to eq("a small summary")
        end

        it "saves the element text into the 'as' accessor" do
          document = @klass.parse("<description>here is a description</description>")
          expect(document.summary).to eq("here is a description")
        end
      end

      describe "using the :with option" do
        describe "and the :value option" do
          before do
            @klass = Class.new do
              include SAXMachine
              element :link, value: :href, with: { foo: "bar" }
            end
          end

          it "saves the value of a matching element" do
            document = @klass.parse("<link href='test' foo='bar'>asdf</link>")
            expect(document.link).to eq("test")
          end

          it "saves the value of the first matching element" do
            document = @klass.parse("<xml><link href='first' foo='bar' /><link href='second' foo='bar' /></xml>")
            expect(document.link).to eq("first")
          end

          describe "and the :as option" do
            before do
              @klass = Class.new do
                include SAXMachine
                element :link, value: :href, as: :url, with: { foo: "bar" }
                element :link, value: :href, as: :second_url, with: { asdf: "jkl" }
              end
            end

            it "saves the value of the first matching element" do
              document = @klass.parse("<xml><link href='first' foo='bar' /><link href='second' asdf='jkl' /><link href='second' foo='bar' /></xml>")
              expect(document.url).to eq("first")
              expect(document.second_url).to eq("second")
            end
          end
        end

        describe "with only one element" do
          before do
            @klass = Class.new do
              include SAXMachine
              element :link, with: { foo: "bar" }
            end
          end

          it "saves the text of an element that has matching attributes" do
            document = @klass.parse("<link foo=\"bar\">match</link>")
            expect(document.link).to eq("match")
          end

          it "does not saves the text of an element that doesn't have matching attributes" do
            document = @klass.parse("<link>no match</link>")
            expect(document.link).to be_nil
          end

          it "saves the text of an element that has matching attributes when it is the second of that type" do
            document = @klass.parse("<xml><link>no match</link><link foo=\"bar\">match</link></xml>")
            expect(document.link).to eq("match")
          end

          it "saves the text of an element that has matching attributes plus a few more" do
            document = @klass.parse("<xml><link>no match</link><link asdf='jkl' foo='bar'>match</link>")
            expect(document.link).to eq("match")
          end
        end

        describe "with multiple elements of same tag" do
          before do
            @klass = Class.new do
              include SAXMachine
              element :link, as: :first, with: { foo: "bar" }
              element :link, as: :second, with: { asdf: "jkl" }
            end
          end

          it "matches the first element" do
            document = @klass.parse("<xml><link>no match</link><link foo=\"bar\">first match</link><link>no match</link></xml>")
            expect(document.first).to eq("first match")
          end

          it "matches the second element" do
            document = @klass.parse("<xml><link>no match</link><link foo='bar'>first match</link><link asdf='jkl'>second match</link><link>hi</link></xml>")
            expect(document.second).to eq("second match")
          end
        end

        describe "with only one element as a regular expression" do
          before do
            @klass = Class.new do
              include SAXMachine
              element :link, with: { foo: /ar$/ }
            end
          end

          it "saves the text of an element that has matching attributes" do
            document = @klass.parse("<link foo=\"bar\">match</link>")
            expect(document.link).to eq("match")
          end

          it "does not saves the text of an element that doesn't have matching attributes" do
            document = @klass.parse("<link>no match</link>")
            expect(document.link).to be_nil
          end

          it "saves the text of an element that has matching attributes when it is the second of that type" do
            document = @klass.parse("<xml><link>no match</link><link foo=\"bar\">match</link></xml>")
            expect(document.link).to eq("match")
          end

          it "saves the text of an element that has matching attributes plus a few more" do
            document = @klass.parse("<xml><link>no match</link><link asdf='jkl' foo='bar'>match</link>")
            expect(document.link).to eq("match")
          end
        end
      end

      describe "using the 'value' option" do
        before do
          @klass = Class.new do
            include SAXMachine
            element :link, value: :foo
          end
        end

        it "saves the attribute value" do
          document = @klass.parse("<link foo='test'>hello</link>")
          expect(document.link).to eq("test")
        end

        it "saves the attribute value when there is no text enclosed by the tag" do
          document = @klass.parse("<link foo='test'></link>")
          expect(document.link).to eq("test")
        end

        it "saves the attribute value when the tag close is in the open" do
          document = @klass.parse("<link foo='test'/>")
          expect(document.link).to eq("test")
        end

        it "saves two different attribute values on a single tag" do
          @klass = Class.new do
            include SAXMachine
            element :link, value: :foo, as: :first
            element :link, value: :bar, as: :second
          end

          document = @klass.parse("<link foo='foo value' bar='bar value'></link>")
          expect(document.first).to eq("foo value")
          expect(document.second).to eq("bar value")
        end

        it "does not fail if one of the attribute hasn't been defined" do
          @klass = Class.new do
            include SAXMachine
            element :link, value: :foo, as: :first
            element :link, value: :bar, as: :second
          end

          document = @klass.parse("<link foo='foo value'></link>")
          expect(document.first).to eq("foo value")
          expect(document.second).to be_nil
        end
      end

      describe "when desiring both the content and attributes of an element" do
        before do
          @klass = Class.new do
            include SAXMachine
            element :link
            element :link, value: :foo, as: :link_foo
            element :link, value: :bar, as: :link_bar
          end
        end

        it "parses the element and attribute values" do
          document = @klass.parse("<link foo='test1' bar='test2'>hello</link>")
          expect(document.link).to eq("hello")
          expect(document.link_foo).to eq("test1")
          expect(document.link_bar).to eq("test2")
        end
      end
    end
  end

  describe "elements" do
    describe "when parsing multiple elements" do
      before do
        @klass = Class.new do
          include SAXMachine
          elements :entry, as: :entries
        end
      end

      it "provides a collection accessor" do
        document = @klass.new
        document.entries << :foo
        expect(document.entries).to eq([:foo])
      end

      it "parses a single element" do
        document = @klass.parse("<entry>hello</entry>")
        expect(document.entries).to eq(["hello"])
      end

      it "parses multiple elements" do
        document = @klass.parse("<xml><entry>hello</entry><entry>world</entry></xml>")
        expect(document.entries).to eq(["hello", "world"])
      end

      it "parses multiple elements when taking an attribute value" do
        attribute_klass = Class.new do
          include SAXMachine
          elements :entry, as: :entries, value: :foo
        end

        doc = attribute_klass.parse("<xml><entry foo='asdf' /><entry foo='jkl' /></xml>")
        expect(doc.entries).to eq(["asdf", "jkl"])
      end
    end

    describe "when using the with and class options" do
      before do
        class Bar
          include SAXMachine
          element :title
        end

        class Foo
          include SAXMachine
          element :title
        end

        class Item
          include SAXMachine
        end

        @klass = Class.new do
          include SAXMachine
          elements :item, as: :items, with: { type: "Bar" }, class: Bar
          elements :item, as: :items, with: { type: /Foo/ }, class: Foo
        end
      end

      it "casts into the correct class" do
        document = @klass.parse("<items><item type=\"Bar\"><title>Bar title</title></item><item type=\"Foo\"><title>Foo title</title></item></items>")
        expect(document.items.size).to eq(2)
        expect(document.items.first).to be_a(Bar)
        expect(document.items.first.title).to eq("Bar title")
        expect(document.items.last).to be_a(Foo)
        expect(document.items.last.title).to eq("Foo title")
      end
    end

    describe "when using the class option" do
      before do
        class Foo
          include SAXMachine
          element :title
        end

        @klass = Class.new do
          include SAXMachine
          elements :entry, as: :entries, class: Foo
        end
      end

      it "parses a single element with children" do
        document = @klass.parse("<entry><title>a title</title></entry>")
        expect(document.entries.size).to eq(1)
        expect(document.entries.first.title).to eq("a title")
      end

      it "parses multiple elements with children" do
        document = @klass.parse("<xml><entry><title>title 1</title></entry><entry><title>title 2</title></entry></xml>")
        expect(document.entries.size).to eq(2)
        expect(document.entries.first.title).to eq("title 1")
        expect(document.entries.last.title).to eq("title 2")
      end

      it "does not parse a top level element that is specified only in a child" do
        document = @klass.parse("<xml><title>no parse</title><entry><title>correct title</title></entry></xml>")
        expect(document.entries.size).to eq(1)
        expect(document.entries.first.title).to eq("correct title")
      end

      it "parses elements, and make attributes and inner text available" do
        class Related
          include SAXMachine
          element "related", as: :item
          element "related", as: :attr, value: "attr"
        end

        class Foo
          elements "related", as: "items", class: Related
        end

        doc = Foo.parse(%{<xml><collection><related attr='baz'>something</related><related>somethingelse</related></collection></xml>})
        expect(doc.items.first).not_to be_nil
        expect(doc.items.size).to eq(2)
        expect(doc.items.first.item).to eq("something")
        expect(doc.items.last.item).to eq("somethingelse")
      end

      it "parses out an attribute value from the tag that starts the collection" do
        class Foo
          element :entry, value: :href, as: :url
        end

        document = @klass.parse("<xml><entry href='http://pauldix.net'><title>paul</title></entry></xml>")
        expect(document.entries.size).to eq(1)
        expect(document.entries.first.title).to eq("paul")
        expect(document.entries.first.url).to eq("http://pauldix.net")
      end
    end
  end

  describe "when dealing with element names containing dashes" do
    it "converts dashes to underscores" do
      class Dashes
        include SAXMachine
        element :dashed_element
      end

      parsed = Dashes.parse("<dashed-element>Text</dashed-element>")
      expect(parsed.dashed_element).to eq "Text"
    end
  end

  describe "full example" do
    before do
      @xml = File.read("spec/fixtures/atom.xml")

      class AtomEntry
        include SAXMachine
        element :title
        element :name, as: :author
        element "feedburner:origLink", as: :url
        element :link, as: :alternate, value: :href, with: { type: "text/html", rel: "alternate" }
        element :summary
        element :content
        element :published
      end

      class Atom
        include SAXMachine
        element :title
        element :link, value: :href, as: :url, with: { type: "text/html" }
        element :link, value: :href, as: :feed_url, with: { type: "application/atom+xml" }
        elements :entry, as: :entries, class: AtomEntry
      end

      @feed = Atom.parse(@xml)
    end

    it "parses the url" do
      expect(@feed.url).to eq("http://www.pauldix.net/")
    end

    it "parses entry url" do
      expect(@feed.entries.first.url).to eq("http://www.pauldix.net/2008/09/marshal-data-to.html?param1=1&param2=2")
      expect(@feed.entries.first.alternate).to eq("http://feeds.feedburner.com/~r/PaulDixExplainsNothing/~3/383536354/marshal-data-to.html?param1=1&param2=2")
    end

    it "parses content" do
      expect(@feed.entries.first.content.strip).to eq(File.read("spec/fixtures/atom-content.html").strip)
    end
  end

  describe "parsing a tree" do
    before do
      @xml = %[
      <categories>
        <category id="1">
          <title>First</title>
          <categories>
            <category id="2">
              <title>Second</title>
            </category>
          </categories>
        </category>
      </categories>
      ]

      class CategoryCollection; end

      class Category
        include SAXMachine
        attr_accessor :id
        element :category, value: :id, as: :id
        element :title
        element :categories, as: :collection, class: CategoryCollection
        ancestor :ancestor
      end

      class CategoryCollection
        include SAXMachine
        elements :category, as: :categories, class: Category
      end

      @collection = CategoryCollection.parse(@xml)
    end

    it "parses the first category" do
      expect(@collection.categories.first.id).to eq("1")
      expect(@collection.categories.first.title).to eq("First")
      expect(@collection.categories.first.ancestor).to eq(@collection)
    end

    it "parses the nested category" do
      expect(@collection.categories.first.collection.categories.first.id).to eq("2")
      expect(@collection.categories.first.collection.categories.first.title).to eq("Second")
    end
  end

  describe "parsing a tree without a collection class" do
    before do
      @xml = %[
      <categories>
        <category id="1">
          <title>First</title>
          <categories>
            <category id="2">
              <title>Second</title>
            </category>
          </categories>
        </category>
      </categories>
      ]

      class CategoryTree
        include SAXMachine
        attr_accessor :id
        element :category, value: :id, as: :id
        element :title
        elements :category, as: :categories, class: CategoryTree
      end

      @collection = CategoryTree.parse(@xml)
    end

    it "parses the first category" do
      expect(@collection.categories.first.id).to eq("1")
      expect(@collection.categories.first.title).to eq("First")
    end

    it "parses the nested category" do
      expect(@collection.categories.first.categories.first.id).to eq("2")
      expect(@collection.categories.first.categories.first.title).to eq("Second")
    end
  end

  describe "with element deeper inside the xml structure" do
    before do
      @xml = %[
        <item id="1">
          <texts>
            <title>Hello</title>
          </texts>
        </item>
      ]

      @klass = Class.new do
        include SAXMachine
        attr_accessor :id
        element :item, value: "id", as: :id
        element :title
      end

      @item = @klass.parse(@xml)
    end

    it "has an id" do
      expect(@item.id).to eq("1")
    end

    it "has a title" do
      expect(@item.title).to eq("Hello")
    end
  end

  describe "with config to pull multiple attributes" do
    before do
      @xml = %[
        <item id="1">
          <author name="John Doe" role="writer" />
        </item>
      ]

      class AuthorElement
        include SAXMachine
        attribute :name
        attribute :role
      end

      class ItemElement
        include SAXMachine
        element :author, class: AuthorElement
      end

      @item = ItemElement.parse(@xml)
    end

    it "has the child element" do
      expect(@item.author).not_to be_nil
    end

    it "has the author name" do
      expect(@item.author.name).to eq("John Doe")
    end

    it "has the author role" do
      expect(@item.author.role).to eq("writer")
    end
  end

  describe "with multiple elements and multiple attributes" do
    before do
      @xml = %[
        <item id="1">
          <author name="John Doe" role="writer" />
          <author name="Jane Doe" role="artist" />
        </item>
      ]

      class AuthorElement2
        include SAXMachine
        attribute :name
        attribute :role
      end

      class ItemElement2
        include SAXMachine
        elements :author, as: :authors, class: AuthorElement2
      end

      @item = ItemElement2.parse(@xml)
    end

    it "has the child elements" do
      expect(@item.authors).not_to be_nil
      expect(@item.authors.count).to eq(2)
    end

    it "has the author names" do
      expect(@item.authors.first.name).to eq("John Doe")
      expect(@item.authors.last.name).to eq("Jane Doe")
    end

    it "has the author roles" do
      expect(@item.authors.first.role).to eq("writer")
      expect(@item.authors.last.role).to eq("artist")
    end
  end

  describe "with mixed attributes and element values" do
    before do
      @xml = %[
        <item id="1">
          <author role="writer">John Doe</author>
        </item>
      ]

      class AuthorElement3
        include SAXMachine
        value :name
        attribute :role
      end

      class ItemElement3
        include SAXMachine
        element :author, class: AuthorElement3
      end

      @item = ItemElement3.parse(@xml)
    end

    it "has the child elements" do
      expect(@item.author).not_to be_nil
    end

    it "has the author names" do
      expect(@item.author.name).to eq("John Doe")
    end

    it "has the author roles" do
      expect(@item.author.role).to eq("writer")
    end
  end

  describe "with multiple mixed attributes and element values" do
    before do
      @xml = %[
        <item id="1">
          <title>sweet</title>
          <author role="writer">John Doe</author>
          <author role="artist">Jane Doe</author>
        </item>
      ]

      class AuthorElement4
        include SAXMachine
        value :name
        attribute :role
      end

      class ItemElement4
        include SAXMachine
        element :title
        elements :author, as: :authors, class: AuthorElement4

        def title=(blah)
          @title = blah
        end
      end

      @item = ItemElement4.parse(@xml)
    end

    it "has the title" do
      expect(@item.title).to eq("sweet")
    end

    it "has the child elements" do
      expect(@item.authors).not_to be_nil
      expect(@item.authors.count).to eq(2)
    end

    it "has the author names" do
      expect(@item.authors.first.name).to eq("John Doe")
      expect(@item.authors.last.name).to eq("Jane Doe")
    end

    it "has the author roles" do
      expect(@item.authors.first.role).to eq("writer")
      expect(@item.authors.last.role).to eq("artist")
    end
  end

  describe "with multiple elements with the same alias" do
    let(:item) { ItemElement5.parse(xml) }

    before do
      class ItemElement5
        include SAXMachine
        element :pubDate, as: :published
        element :"dc:date", as: :published
      end
    end

    describe "only first defined" do
      let(:xml) { "<item xmlns:dc='http://www.example.com'><pubDate>first value</pubDate></item>" }

      it "has first value" do
        expect(item.published).to eq("first value")
      end
    end

    describe "only last defined" do
      let(:xml) { "<item xmlns:dc='http://www.example.com'><dc:date>last value</dc:date></item>" }

      it "has last value" do
        expect(item.published).to eq("last value")
      end
    end

    describe "both defined" do
      let(:xml) { "<item xmlns:dc='http://www.example.com'><pubDate>first value</pubDate><dc:date>last value</dc:date></item>" }

      it "has last value" do
        expect(item.published).to eq("last value")
      end
    end

    describe "both defined but order is reversed" do
      let(:xml) { "<item xmlns:dc='http://www.example.com'><dc:date>last value</dc:date><pubDate>first value</pubDate></item>" }

      it "has first value" do
        expect(item.published).to eq("first value")
      end
    end

    describe "both defined but last is empty" do
      let(:xml) { "<item xmlns:dc='http://www.example.com'><pubDate>first value</pubDate><dc:date></dc:date></item>" }

      it "has first value" do
        expect(item.published).to eq("first value")
      end
    end
  end

  describe "with error handling" do
    before do
      @xml = %[
        <item id="1">
          <title>sweet</title>
      ]

      class ItemElement5
        include SAXMachine
        element :title
      end

      @errors = []
      @warnings = []
      @item = ItemElement5.parse(
        @xml,
        ->(x) { @errors << x },
        ->(x) { @warnings << x },
      )
    end

    it "has error" do
      expect(@errors.uniq.size).to eq(1)
    end

    it "has no warning" do
      expect(@warnings.uniq.size).to eq(0)
    end
  end

  describe "with io as a input" do
    before do
      @io = StringIO.new('<item id="1"><title>sweet</title></item>')

      class IoParser
        include SAXMachine
        element :title
      end

      @item = ItemElement5.parse(@io)
    end

    it "parses" do
      expect(@item.title).to eq("sweet")
    end
  end
end
