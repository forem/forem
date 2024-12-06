# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Capybara do
  include Capybara::RSpecMatchers
  describe '.string' do
    let :string do
      described_class.string <<-STRING
        <html>
          <head>
            <title>simple_node</title>
          </head>
          <body>
            <svg><title>not document title</title></svg>
            <div id="page">
              <div id="content">
                <h1 data="fantastic">Totally awesome</h1>
                <p>Yes it is</p>
              </div>

              <form>
                <input type="text" name="bleh" disabled="disabled"/>
                <input type="text" name="meh"/>
              </form>

              <div id="footer">
                <p>c2010</p>
                <p>Jonas Nicklas</p>
                <input type="text" name="foo" value="bar"/>
                <select name="animal">
                  <option>Monkey</option>
                  <option selected="selected">Capybara</option>
                </select>
              </div>

              <div id="hidden" style="display: none">
                <p id="secret">Secret</p>
              </div>

              <section>
                <div class="subsection"></div>
              </section>
            </div>
          </body>
        </html>
      STRING
    end

    it 'allows using matchers' do
      expect(string).to have_css('#page')
      expect(string).not_to have_css('#does-not-exist')
    end

    it 'allows using custom matchers' do
      described_class.add_selector :lifeform do
        xpath { |name| ".//option[contains(.,'#{name}')]" }
      end
      expect(string).to have_selector(:id, 'page')
      expect(string).not_to have_selector(:id, 'does-not-exist')
      expect(string).to have_selector(:lifeform, 'Monkey')
      expect(string).not_to have_selector(:lifeform, 'Gorilla')
    end

    it 'allows custom matcher using css' do
      described_class.add_selector :section do
        css { |css_class| "section .#{css_class}" }
      end
      expect(string).to     have_selector(:section, 'subsection')
      expect(string).not_to have_selector(:section, 'section_8')
    end

    it 'allows using matchers with text option' do
      expect(string).to have_css('h1', text: 'Totally awesome')
      expect(string).not_to have_css('h1', text: 'Not so awesome')
    end

    it 'allows finding only visible nodes' do
      expect(string.all(:css, '#secret', visible: true)).to be_empty
      expect(string.all(:css, '#secret', visible: false).size).to eq(1)
    end

    it 'allows finding elements and extracting text from them' do
      expect(string.find('//h1').text).to eq('Totally awesome')
    end

    it 'allows finding elements and extracting attributes from them' do
      expect(string.find('//h1')[:data]).to eq('fantastic')
    end

    it 'allows finding elements and extracting the tag name from them' do
      expect(string.find('//h1').tag_name).to eq('h1')
    end

    it 'allows finding elements and extracting the path' do
      expect(string.find('//h1').path).to eq('/html/body/div/div[1]/h1')
    end

    it 'allows finding elements and extracting the value' do
      expect(string.find('//div/input').value).to eq('bar')
      expect(string.find('//select').value).to eq('Capybara')
    end

    it 'allows finding elements and checking if they are visible' do
      expect(string.find('//h1')).to be_visible
      expect(string.find(:css, '#secret', visible: false)).not_to be_visible
    end

    it 'allows finding elements and checking if they are disabled' do
      expect(string.find('//form/input[@name="bleh"]')).to be_disabled
      expect(string.find('//form/input[@name="meh"]')).not_to be_disabled
    end

    it 'allows finding siblings' do
      h1 = string.find(:css, 'h1')
      expect(h1).to have_sibling(:css, 'p', text: 'Yes it is')
      expect(h1).not_to have_sibling(:css, 'p', text: 'Jonas Nicklas')
    end

    it 'allows finding ancestor' do
      h1 = string.find(:css, 'h1')
      expect(h1).to have_ancestor(:css, '#content')
      expect(h1).not_to have_ancestor(:css, '#footer')
    end

    it 'drops illegal fragments when using gumbo' do
      skip 'libxml is less strict than Gumbo' unless Nokogiri.respond_to?(:HTML5)
      described_class.use_html5_parsing = true
      expect(described_class.string('<td>1</td>')).not_to have_css('td')
    end

    it 'can disable use of HTML5 parsing' do
      skip "Test doesn't make sense unlesss HTML5 parsing is loaded (Nokogumbo or Nokogiri >= 1.12.0)" unless Nokogiri.respond_to?(:HTML5)
      described_class.use_html5_parsing = false
      expect(described_class.string('<td>1</td>')).to have_css('td')
    end

    describe '#title' do
      it 'returns the page title' do
        expect(string.title).to eq('simple_node')
      end
    end

    describe '#has_title?' do
      it 'returns whether the page has the given title' do
        expect(string.has_title?('simple_node')).to be true
        expect(string.has_title?('monkey')).to be false
      end

      it 'allows regexp matches' do
        expect(string.has_title?(/s[a-z]+_node/)).to be true
        expect(string.has_title?(/monkey/)).to be false
      end
    end

    describe '#has_no_title?' do
      it 'returns whether the page does not have the given title' do
        expect(string.has_no_title?('simple_node')).to be false
        expect(string.has_no_title?('monkey')).to be true
      end

      it 'allows regexp matches' do
        expect(string.has_no_title?(/s[a-z]+_node/)).to be false
        expect(string.has_no_title?(/monkey/)).to be true
      end
    end
  end
end
