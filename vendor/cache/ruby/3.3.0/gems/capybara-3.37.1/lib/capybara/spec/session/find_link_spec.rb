# frozen_string_literal: true

Capybara::SpecHelper.spec '#find_link' do
  before do
    @session.visit('/with_html')
  end

  it 'should find any link' do
    expect(@session.find_link('foo').text).to eq('ullamco')
    expect(@session.find_link('labore')[:href]).to match %r{/with_simple_html$}
  end

  context 'aria_label attribute with Capybara.enable_aria_label' do
    it 'should find when true' do
      Capybara.enable_aria_label = true
      expect(@session.find_link('Go to simple')[:href]).to match %r{/with_simple_html$}
    end

    it 'should not find when false' do
      Capybara.enable_aria_label = false
      expect { @session.find_link('Go to simple') }.to raise_error(Capybara::ElementNotFound)
    end
  end

  it 'casts to string' do
    expect(@session.find_link(:foo).text).to eq('ullamco')
  end

  it "should raise error if the field doesn't exist" do
    expect do
      @session.find_link('Does not exist')
    end.to raise_error(Capybara::ElementNotFound)
  end

  context 'with :exact option' do
    it 'should accept partial matches when false' do
      expect(@session.find_link('abo', exact: false).text).to eq('labore')
    end

    it 'should not accept partial matches when true' do
      expect do
        @session.find_link('abo', exact: true)
      end.to raise_error(Capybara::ElementNotFound)
    end
  end

  context 'without locator' do
    it 'should use options' do
      expect(@session.find_link(href: '#anchor').text).to eq 'Normal Anchor'
    end
  end

  context 'download filter' do
    it 'finds a download link' do
      expect(@session.find_link('Download Me', download: true).text).to eq 'Download Me'
    end

    it "doesn't find a download link if download is false" do
      expect { @session.find_link('Download Me', download: false) }.to raise_error Capybara::ElementNotFound
    end

    it 'finds a renaming download link' do
      expect(@session.find_link(download: 'other.csv').text).to eq 'Download Other'
    end

    it 'raises if passed an invalid value' do
      expect { @session.find_link(download: 37) }.to raise_error ArgumentError
    end
  end
end
