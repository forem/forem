# frozen_string_literal: true

Capybara::SpecHelper.spec '#all' do
  before do
    @session.visit('/with_html')
  end

  it 'should find all elements using the given locator' do
    expect(@session.all('//p').size).to eq(3)
    expect(@session.all('//h1').first.text).to eq('This is a test')
    expect(@session.all("//input[@id='test_field']").first.value).to eq('monkey')
  end

  it 'should return an empty array when nothing was found' do
    expect(@session.all('//div[@id="nosuchthing"]')).to be_empty
  end

  it 'should wait for matching elements to appear', requires: [:js] do
    Capybara.default_max_wait_time = 2
    @session.visit('/with_js')
    @session.click_link('Click me')
    expect(@session.all(:css, 'a#has-been-clicked')).not_to be_empty
  end

  it 'should not wait if `minimum: 0` option is specified', requires: [:js] do
    @session.visit('/with_js')
    @session.click_link('Click me')
    expect(@session.all(:css, 'a#has-been-clicked', minimum: 0)).to be_empty
  end

  it 'should accept an XPath instance', :exact_false do
    @session.visit('/form')
    @xpath = Capybara::Selector.new(:fillable_field, config: {}, format: :xpath).call('Name')
    expect(@xpath).to be_a(::XPath::Union)
    @result = @session.all(@xpath).map(&:value)
    expect(@result).to include('Smith', 'John', 'John Smith')
  end

  it 'should allow reversing the order' do
    @session.visit('/form')
    fields = @session.all(:fillable_field, 'Name', exact: false).to_a
    reverse_fields = @session.all(:fillable_field, 'Name', order: :reverse, exact: false).to_a
    expect(fields).to eq(reverse_fields.reverse)
  end

  it 'should raise an error when given invalid options' do
    expect { @session.all('//p', schmoo: 'foo') }.to raise_error(ArgumentError)
  end

  it 'should not reload by default', requires: [:driver] do
    paras = @session.all(:css, 'p', minimum: 3)
    expect { paras[0].text }.not_to raise_error
    @session.refresh
    expect { paras[0].text }.to raise_error do |err|
      expect(err).to be_an_invalid_element_error(@session)
    end
  end

  context 'with allow_reload' do
    it 'should reload if true' do
      paras = @session.all(:css, 'p', allow_reload: true, minimum: 3)
      expect { paras[0].text }.not_to raise_error
      @session.refresh
      sleep 1 # Ensure page has started to reload
      expect(paras[0]).to have_text('Lorem ipsum dolor')
      expect(paras[1]).to have_text('Duis aute irure dolor')
    end

    it 'should not reload if false', requires: [:driver] do
      paras = @session.all(:css, 'p', allow_reload: false, minimum: 3)
      expect { paras[0].text }.not_to raise_error
      @session.refresh
      sleep 1 # Ensure page has started to reload
      expect { paras[0].text }.to raise_error do |err|
        expect(err).to be_an_invalid_element_error(@session)
      end
      expect { paras[2].text }.to raise_error do |err|
        expect(err).to be_an_invalid_element_error(@session)
      end
    end
  end

  context 'with css selectors' do
    it 'should find all elements using the given selector' do
      expect(@session.all(:css, 'h1').first.text).to eq('This is a test')
      expect(@session.all(:css, "input[id='test_field']").first.value).to eq('monkey')
    end

    it 'should find all elements when given a list of selectors' do
      expect(@session.all(:css, 'h1, p').size).to eq(4)
    end
  end

  context 'with xpath selectors' do
    it 'should find the first element using the given locator' do
      expect(@session.all(:xpath, '//h1').first.text).to eq('This is a test')
      expect(@session.all(:xpath, "//input[@id='test_field']").first.value).to eq('monkey')
    end

    it 'should use alternated regex for :id' do
      expect(@session.all(:xpath, './/h2', id: /h2/).unfiltered_size).to eq 3
      expect(@session.all(:xpath, './/h2', id: /h2(one|two)/).unfiltered_size).to eq 2
    end
  end

  context 'with css as default selector' do
    before { Capybara.default_selector = :css }

    it 'should find the first element using the given locator' do
      expect(@session.all('h1').first.text).to eq('This is a test')
      expect(@session.all("input[id='test_field']").first.value).to eq('monkey')
    end
  end

  context 'with visible filter' do
    it 'should only find visible nodes when true' do
      expect(@session.all(:css, 'a.simple', visible: true).size).to eq(1)
    end

    it 'should find nodes regardless of whether they are invisible when false' do
      expect(@session.all(:css, 'a.simple', visible: false).size).to eq(2)
    end

    it 'should default to Capybara.ignore_hidden_elements' do
      Capybara.ignore_hidden_elements = true
      expect(@session.all(:css, 'a.simple').size).to eq(1)
      Capybara.ignore_hidden_elements = false
      expect(@session.all(:css, 'a.simple').size).to eq(2)
    end

    context 'with per session config', requires: [:psc] do
      it 'should use the sessions ignore_hidden_elements', psc: true do
        Capybara.ignore_hidden_elements = true
        @session.config.ignore_hidden_elements = false
        expect(Capybara.ignore_hidden_elements).to be(true)
        expect(@session.all(:css, 'a.simple').size).to eq(2)
        @session.config.ignore_hidden_elements = true
        expect(@session.all(:css, 'a.simple').size).to eq(1)
      end
    end
  end

  context 'with obscured filter', requires: [:css] do
    it 'should only find nodes on top in the viewport when false' do
      expect(@session.all(:css, 'a.simple', obscured: false).size).to eq(1)
    end

    it 'should not find nodes on top outside the viewport when false' do
      expect(@session.all(:link, 'Download Me', obscured: false).size).to eq(0)
      @session.scroll_to(@session.find_link('Download Me'))
      expect(@session.all(:link, 'Download Me', obscured: false).size).to eq(1)
    end

    it 'should find top nodes outside the viewport when true' do
      expect(@session.all(:link, 'Download Me', obscured: true).size).to eq(1)
      @session.scroll_to(@session.find_link('Download Me'))
      expect(@session.all(:link, 'Download Me', obscured: true).size).to eq(0)
    end

    it 'should only find non-top nodes when true' do
      # Also need visible: false so visibility is ignored
      expect(@session.all(:css, 'a.simple', visible: false, obscured: true).size).to eq(1)
    end
  end

  context 'with element count filters' do
    context ':count' do
      it 'should succeed when the number of elements founds matches the expectation' do
        expect { @session.all(:css, 'h1, p', count: 4) }.not_to raise_error
      end

      it 'should raise ExpectationNotMet when the number of elements founds does not match the expectation' do
        expect { @session.all(:css, 'h1, p', count: 5) }.to raise_error(Capybara::ExpectationNotMet)
      end
    end

    context ':minimum' do
      it 'should succeed when the number of elements founds matches the expectation' do
        expect { @session.all(:css, 'h1, p', minimum: 0) }.not_to raise_error
      end

      it 'should raise ExpectationNotMet when the number of elements founds does not match the expectation' do
        expect { @session.all(:css, 'h1, p', minimum: 5) }.to raise_error(Capybara::ExpectationNotMet)
      end
    end

    context ':maximum' do
      it 'should succeed when the number of elements founds matches the expectation' do
        expect { @session.all(:css, 'h1, p', maximum: 4) }.not_to raise_error
      end

      it 'should raise ExpectationNotMet when the number of elements founds does not match the expectation' do
        expect { @session.all(:css, 'h1, p', maximum: 0) }.to raise_error(Capybara::ExpectationNotMet)
      end
    end

    context ':between' do
      it 'should succeed when the number of elements founds matches the expectation' do
        expect { @session.all(:css, 'h1, p', between: 2..7) }.not_to raise_error
      end

      it 'should raise ExpectationNotMet when the number of elements founds does not match the expectation' do
        expect { @session.all(:css, 'h1, p', between: 0..3) }.to raise_error(Capybara::ExpectationNotMet)
      end

      it 'treats an endless range as minimum' do
        expect { @session.all(:css, 'h1, p', between: 2..) }.not_to raise_error
        expect { @session.all(:css, 'h1, p', between: 5..) }.to raise_error(Capybara::ExpectationNotMet)
      end

      it 'treats a beginless range as maximum' do
        expect { @session.all(:css, 'h1, p', between: ..7) }.not_to raise_error
        expect { @session.all(:css, 'h1, p', between: ..3) }.to raise_error(Capybara::ExpectationNotMet)
      end
    end

    context 'with multiple count filters' do
      it 'ignores other filters when :count is specified' do
        o = { count: 4,
              minimum: 5,
              maximum: 0,
              between: 0..3 }
        expect { @session.all(:css, 'h1, p', **o) }.not_to raise_error
      end

      context 'with no :count expectation' do
        it 'fails if :minimum is not met' do
          o = { minimum: 5,
                maximum: 4,
                between: 2..7 }
          expect { @session.all(:css, 'h1, p', **o) }.to raise_error(Capybara::ExpectationNotMet)
        end

        it 'fails if :maximum is not met' do
          o = { minimum: 0,
                maximum: 0,
                between: 2..7 }
          expect { @session.all(:css, 'h1, p', **o) }.to raise_error(Capybara::ExpectationNotMet)
        end

        it 'fails if :between is not met' do
          o = { minimum: 0,
                maximum: 4,
                between: 0..3 }
          expect { @session.all(:css, 'h1, p', **o) }.to raise_error(Capybara::ExpectationNotMet)
        end

        it 'succeeds if all combineable expectations are met' do
          o = { minimum: 0,
                maximum: 4,
                between: 2..7 }
          expect { @session.all(:css, 'h1, p', **o) }.not_to raise_error
        end
      end
    end
  end

  context 'within a scope' do
    before do
      @session.visit('/with_scope')
    end

    it 'should find any element using the given locator' do
      @session.within(:xpath, "//div[@id='for_bar']") do
        expect(@session.all('.//li').size).to eq(2)
      end
    end
  end

  it 'should have #find_all as an alias' do
    expect(Capybara::Node::Finders.instance_method(:all)).to eq Capybara::Node::Finders.instance_method(:find_all)
    expect(@session.find_all('//p').size).to eq(3)
  end
end
