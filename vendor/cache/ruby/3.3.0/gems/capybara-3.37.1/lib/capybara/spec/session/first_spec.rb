# frozen_string_literal: true

Capybara::SpecHelper.spec '#first' do
  before do
    @session.visit('/with_html')
  end

  it 'should find the first element using the given locator' do
    expect(@session.first('//h1').text).to eq('This is a test')
    expect(@session.first("//input[@id='test_field']").value).to eq('monkey')
  end

  it 'should raise ElementNotFound when nothing was found' do
    expect do
      @session.first('//div[@id="nosuchthing"]')
    end.to raise_error Capybara::ElementNotFound
  end

  it 'should return nil when nothing was found if count options allow no results' do
    expect(@session.first('//div[@id="nosuchthing"]', minimum: 0)).to be_nil
    expect(@session.first('//div[@id="nosuchthing"]', count: 0)).to be_nil
    expect(@session.first('//div[@id="nosuchthing"]', between: (0..3))).to be_nil
  end

  it 'should accept an XPath instance' do
    @session.visit('/form')
    @xpath = Capybara::Selector.new(:fillable_field, config: {}, format: :xpath).call('First Name')
    expect(@xpath).to be_a(::XPath::Union)
    expect(@session.first(@xpath).value).to eq('John')
  end

  it 'should raise when unused parameters are passed' do
    expect do
      @session.first(:css, 'h1', 'unused text')
    end.to raise_error ArgumentError, /Unused parameters passed.*unused text/
  end

  context 'with css selectors' do
    it 'should find the first element using the given selector' do
      expect(@session.first(:css, 'h1').text).to eq('This is a test')
      expect(@session.first(:css, "input[id='test_field']").value).to eq('monkey')
    end
  end

  context 'with xpath selectors' do
    it 'should find the first element using the given locator' do
      expect(@session.first(:xpath, '//h1').text).to eq('This is a test')
      expect(@session.first(:xpath, "//input[@id='test_field']").value).to eq('monkey')
    end
  end

  context 'with css as default selector' do
    before { Capybara.default_selector = :css }

    it 'should find the first element using the given locator' do
      expect(@session.first('h1').text).to eq('This is a test')
      expect(@session.first("input[id='test_field']").value).to eq('monkey')
    end
  end

  context 'with visible filter' do
    it 'should only find visible nodes when true' do
      expect do
        @session.first(:css, 'a#invisible', visible: true)
      end.to raise_error Capybara::ElementNotFound
    end

    it 'should find nodes regardless of whether they are invisible when false' do
      expect(@session.first(:css, 'a#invisible', visible: false)).to be_truthy
      expect(@session.first(:css, 'a#invisible', visible: false, text: 'hidden link')).to be_truthy
      expect(@session.first(:css, 'a#visible', visible: false)).to be_truthy
    end

    it 'should find nodes regardless of whether they are invisible when :all' do
      expect(@session.first(:css, 'a#invisible', visible: :all)).to be_truthy
      expect(@session.first(:css, 'a#invisible', visible: :all, text: 'hidden link')).to be_truthy
      expect(@session.first(:css, 'a#visible', visible: :all)).to be_truthy
    end

    it 'should find only hidden nodes when :hidden' do
      expect(@session.first(:css, 'a#invisible', visible: :hidden)).to be_truthy
      expect(@session.first(:css, 'a#invisible', visible: :hidden, text: 'hidden link')).to be_truthy
      expect do
        @session.first(:css, 'a#invisible', visible: :hidden, text: 'not hidden link')
      end.to raise_error Capybara::ElementNotFound
      expect do
        @session.first(:css, 'a#visible', visible: :hidden)
      end.to raise_error Capybara::ElementNotFound
    end

    it 'should find only visible nodes when :visible' do
      expect do
        @session.first(:css, 'a#invisible', visible: :visible)
      end.to raise_error Capybara::ElementNotFound
      expect do
        @session.first(:css, 'a#invisible', visible: :visible, text: 'hidden link')
      end.to raise_error Capybara::ElementNotFound
      expect(@session.first(:css, 'a#visible', visible: :visible)).to be_truthy
    end

    it 'should default to Capybara.ignore_hidden_elements' do
      Capybara.ignore_hidden_elements = true
      expect do
        @session.first(:css, 'a#invisible')
      end.to raise_error Capybara::ElementNotFound
      Capybara.ignore_hidden_elements = false
      expect(@session.first(:css, 'a#invisible')).to be_truthy
      expect(@session.first(:css, 'a')).to be_truthy
    end
  end

  context 'within a scope' do
    before do
      @session.visit('/with_scope')
    end

    it 'should find the first element using the given locator' do
      @session.within(:xpath, "//div[@id='for_bar']") do
        expect(@session.first('.//form')).to be_truthy
      end
    end
  end

  context 'waiting behavior', requires: [:js] do
    before do
      @session.visit('/with_js')
    end

    it 'should not wait if minimum: 0' do
      @session.click_link('clickable')
      Capybara.using_wait_time(3) do
        start_time = Time.now
        expect(@session.first(:css, 'a#has-been-clicked', minimum: 0)).to be_nil
        expect(Time.now - start_time).to be < 3
      end
    end

    it 'should wait for at least one match by default' do
      Capybara.using_wait_time(3) do
        @session.click_link('clickable')
        expect(@session.first(:css, 'a#has-been-clicked')).not_to be_nil
      end
    end

    it 'should raise an error after waiting if no match' do
      @session.click_link('clickable')
      Capybara.using_wait_time(3) do
        start_time = Time.now
        expect do
          @session.first(:css, 'a#not-a-real-link')
        end.to raise_error Capybara::ElementNotFound
        expect(Time.now - start_time).to be > 3
      end
    end
  end
end
