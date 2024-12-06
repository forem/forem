# frozen_string_literal: true

require 'spec_helper'
require 'capybara/dsl'
require 'capybara/rspec/matchers'
require 'benchmark'

# rubocop:disable RSpec/ExpectActual

RSpec.shared_examples Capybara::RSpecMatchers do |session, _mode|
  include Capybara::DSL
  include Capybara::RSpecMatchers

  describe 'have_css matcher' do
    it 'gives proper description' do
      expect(have_css('h1').description).to eq('have visible css "h1"')
    end

    context 'on a string' do
      context 'with should' do
        it 'passes if has_css? returns true' do
          expect('<h1>Text</h1>').to have_css('h1')
        end

        it 'fails if has_css? returns false' do
          expect do
            expect('<h1>Text</h1>').to have_css('h2')
          end.to raise_error(/expected to find css "h2" but there were no matches/)
        end

        it 'passes if matched node count equals expected count' do
          expect('<h1>Text</h1>').to have_css('h1', count: 1)
        end

        it 'fails if matched node count does not equal expected count' do
          expect do
            expect('<h1>Text</h1>').to have_css('h1', count: 2)
          end.to raise_error('expected to find visible css "h1" 2 times, found 1 match: "Text"')
        end

        it 'fails if matched node count is less than expected minimum count' do
          expect do
            expect('<h1>Text</h1>').to have_css('p', minimum: 1)
          end.to raise_error('expected to find css "p" at least 1 time but there were no matches')
        end

        it 'fails if matched node count is more than expected maximum count' do
          expect do
            expect('<h1>Text</h1><h1>Text</h1><h1>Text</h1>').to have_css('h1', maximum: 2)
          end.to raise_error('expected to find visible css "h1" at most 2 times, found 3 matches: "Text", "Text", "Text"')
        end

        it 'fails if matched node count does not belong to expected range' do
          expect do
            expect('<h1>Text</h1>').to have_css('h1', between: 2..3)
          end.to raise_error('expected to find visible css "h1" between 2 and 3 times, found 1 match: "Text"')
        end
      end

      context 'with should_not' do
        it 'passes if has_no_css? returns true' do
          expect('<h1>Text</h1>').not_to have_css('h2')
        end

        it 'fails if has_no_css? returns false' do
          expect do
            expect('<h1>Text</h1>').not_to have_css('h1')
          end.to raise_error(/expected not to find visible css "h1"/)
        end

        it 'passes if matched node count does not equal expected count' do
          expect('<h1>Text</h1>').not_to have_css('h1', count: 2)
        end

        it 'fails if matched node count equals expected count' do
          expect do
            expect('<h1>Text</h1>').not_to have_css('h1', count: 1)
          end.to raise_error(/expected not to find visible css "h1"/)
        end
      end

      it 'supports compounding' do
        expect('<h1>Text</h1><h2>Text</h2>').to have_css('h1').and have_css('h2')
        expect('<h1>Text</h1><h2>Text</h2>').to have_css('h3').or have_css('h1')
        expect('<h1>Text</h1><h2>Text</h2>').to have_no_css('h4').and have_css('h2')
        expect('<h1>Text</h1><h2>Text</h2>').to have_no_css('h2').or have_css('h1')
      end
    end

    context 'on a page or node' do
      before do
        session.visit('/with_html')
      end

      context 'with should' do
        it 'passes if has_css? returns true' do
          expect(session).to have_css('h1')
        end

        it 'fails if has_css? returns false' do
          expect do
            expect(session).to have_css('h1#doesnotexist')
          end.to raise_error(/expected to find css "h1#doesnotexist" but there were no matches/)
        end
      end

      context 'with should_not' do
        it 'passes if has_no_css? returns true' do
          expect(session).not_to have_css('h1#doesnotexist')
        end

        it 'fails if has_no_css? returns false' do
          expect do
            expect(session).not_to have_css('h1')
          end.to raise_error(/expected not to find visible css "h1"/)
        end
      end
    end
  end

  describe 'have_xpath matcher' do
    it 'gives proper description' do
      expect(have_xpath('//h1').description).to eq("have visible xpath \"\/\/h1\"")
    end

    context 'on a string' do
      context 'with should' do
        it 'passes if has_xpath? returns true' do
          expect('<h1>Text</h1>').to have_xpath('//h1')
        end

        it 'fails if has_xpath? returns false' do
          expect do
            expect('<h1>Text</h1>').to have_xpath('//h2')
          end.to raise_error(%r{expected to find xpath "//h2" but there were no matches})
        end
      end

      context 'with should_not' do
        it 'passes if has_no_xpath? returns true' do
          expect('<h1>Text</h1>').not_to have_xpath('//h2')
        end

        it 'fails if has_no_xpath? returns false' do
          expect do
            expect('<h1>Text</h1>').not_to have_xpath('//h1')
          end.to raise_error(%r{expected not to find visible xpath "//h1"})
        end
      end

      it 'supports compounding' do
        expect('<h1>Text</h1><h2>Text</h2>').to have_xpath('//h1').and have_xpath('//h2')
        expect('<h1>Text</h1><h2>Text</h2>').to have_xpath('//h3').or have_xpath('//h1')
        expect('<h1>Text</h1><h2>Text</h2>').to have_no_xpath('//h4').and have_xpath('//h1')
        expect('<h1>Text</h1><h2>Text</h2>').to have_no_xpath('//h4').or have_xpath('//h4')
      end
    end

    context 'on a page or node' do
      before do
        session.visit('/with_html')
      end

      context 'with should' do
        it 'passes if has_xpath? returns true' do
          expect(session).to have_xpath('//h1')
        end

        it 'fails if has_xpath? returns false' do
          expect do
            expect(session).to have_xpath("//h1[@id='doesnotexist']")
          end.to raise_error(%r{expected to find xpath "//h1\[@id='doesnotexist'\]" but there were no matches})
        end
      end

      context 'with should_not' do
        it 'passes if has_no_xpath? returns true' do
          expect(session).not_to have_xpath('//h1[@id="doesnotexist"]')
        end

        it 'fails if has_no_xpath? returns false' do
          expect do
            expect(session).not_to have_xpath('//h1')
          end.to raise_error(%r{expected not to find visible xpath "//h1"})
        end
      end
    end
  end

  describe 'have_selector matcher' do
    it 'gives proper description' do
      matcher = have_selector('//h1')
      expect('<h1>Text</h1>').to matcher
      expect(matcher.description).to eq('have visible xpath "//h1"')
    end

    context 'on a string' do
      context 'with should' do
        it 'passes if has_selector? returns true' do
          expect('<h1>Text</h1>').to have_selector('//h1')
        end

        it 'fails if has_selector? returns false' do
          expect do
            expect('<h1>Text</h1>').to have_selector('//h2')
          end.to raise_error(%r{expected to find xpath "//h2" but there were no matches})
        end
      end

      context 'with should_not' do
        it 'passes if has_no_selector? returns true' do
          expect('<h1>Text</h1>').not_to have_selector(:css, 'h2')
        end

        it 'fails if has_no_selector? returns false' do
          expect do
            expect('<h1>Text</h1>').not_to have_selector(:css, 'h1')
          end.to raise_error(/expected not to find visible css "h1"/)
        end
      end
    end

    context 'on a page or node' do
      before do
        session.visit('/with_html')
      end

      context 'with should' do
        it 'passes if has_selector? returns true' do
          expect(session).to have_selector('//h1', text: 'test')
        end

        it 'fails if has_selector? returns false' do
          expect do
            expect(session).to have_selector("//h1[@id='doesnotexist']")
          end.to raise_error(%r{expected to find xpath "//h1\[@id='doesnotexist'\]" but there were no matches})
        end

        it 'includes text in error message' do
          expect do
            expect(session).to have_selector('//h1', text: 'wrong text')
          end.to raise_error(%r{expected to find visible xpath "//h1" with text "wrong text" but there were no matches})
        end
      end

      context 'with should_not' do
        it 'passes if has_no_css? returns true' do
          expect(session).not_to have_selector(:css, 'h1#doesnotexist')
        end

        it 'fails if has_no_selector? returns false' do
          expect do
            expect(session).not_to have_selector(:css, 'h1', text: 'test')
          end.to raise_error(/expected not to find visible css "h1" with text "test"/)
        end
      end
    end

    it 'supports compounding' do
      expect('<h1>Text</h1><h2>Text</h2>').to have_selector('//h1').and have_selector('//h2')
      expect('<h1>Text</h1><h2>Text</h2>').to have_selector('//h3').or have_selector('//h1')
      expect('<h1>Text</h1><h2>Text</h2>').to have_no_selector('//h3').and have_selector('//h1')
    end
  end

  describe 'have_content matcher' do
    it 'gives proper description' do
      expect(have_content('Text').description).to eq('have text "Text"')
    end

    context 'on a string' do
      context 'with should' do
        it 'passes if has_content? returns true' do
          expect('<h1>Text</h1>').to have_content('Text')
        end

        it 'passes if has_content? returns true using regexp' do
          expect('<h1>Text</h1>').to have_content(/ext/)
        end

        it 'fails if has_content? returns false' do
          expect do
            expect('<h1>Text</h1>').to have_content('No such Text')
          end.to raise_error(/expected to find text "No such Text" in "Text"/)
        end
      end

      context 'with should_not' do
        it 'passes if has_no_content? returns true' do
          expect('<h1>Text</h1>').not_to have_content('No such Text')
        end

        it 'passes because escapes any characters that would have special meaning in a regexp' do
          expect('<h1>Text</h1>').not_to have_content('.')
        end

        it 'fails if has_no_content? returns false' do
          expect do
            expect('<h1>Text</h1>').not_to have_content('Text')
          end.to raise_error(/expected not to find text "Text" in "Text"/)
        end
      end
    end

    context 'on a page or node' do
      before do
        session.visit('/with_html')
      end

      context 'with should' do
        it 'passes if has_content? returns true' do
          expect(session).to have_content('This is a test')
        end

        it 'passes if has_content? returns true using regexp' do
          expect(session).to have_content(/test/)
        end

        it 'fails if has_content? returns false' do
          expect do
            expect(session).to have_content('No such Text')
          end.to raise_error(/expected to find text "No such Text" in "(.*)This is a test(.*)"/)
        end

        context 'with default selector CSS' do
          before { Capybara.default_selector = :css }

          after { Capybara.default_selector = :xpath }

          it 'fails if has_content? returns false' do
            expect do
              expect(session).to have_content('No such Text')
            end.to raise_error(/expected to find text "No such Text" in "(.*)This is a test(.*)"/)
          end
        end
      end

      context 'with should_not' do
        it 'passes if has_no_content? returns true' do
          expect(session).not_to have_content('No such Text')
        end

        it 'fails if has_no_content? returns false' do
          expect do
            expect(session).not_to have_content('This is a test')
          end.to raise_error(/expected not to find text "This is a test"/)
        end

        it 'not_to have_content behaves the same as to have_no_content' do
          Capybara.using_wait_time(5) do
            expect(session).to have_content('This is a test')
            start = Time.now
            expect(session).to have_no_content('No such Text')
            to_time = Time.now
            expect(session).not_to have_content('No such Text')
            not_to_time = Time.now
            expect(not_to_time - to_time).to be_within(0.5).of(to_time - start)
          end
        end
      end
    end

    it 'supports compounding' do
      expect('<h1>Text</h1><h2>And</h2>').to have_content('Text').and have_content('And')
      expect('<h1>Text</h1><h2>Or</h2>').to have_content('XYZ').or have_content('Or')
      expect('<h1>Text</h1><h2>Or</h2>').to have_no_content('XYZ').and have_content('Or')
    end
  end

  describe 'have_text matcher' do
    it 'gives proper description' do
      expect(have_text('Text').description).to eq('have text "Text"')
    end

    context 'on a string' do
      context 'with should' do
        it 'passes if text contains given string' do
          expect('<h1>Text</h1>').to have_text('Text')
        end

        it 'passes if text matches given regexp' do
          expect('<h1>Text</h1>').to have_text(/ext/)
        end

        it "fails if text doesn't contain given string" do
          expect do
            expect('<h1>Text</h1>').to have_text('No such Text')
          end.to raise_error(/expected to find text "No such Text" in "Text"/)
        end

        it "fails if text doesn't match given regexp" do
          expect do
            expect('<h1>Text</h1>').to have_text(/No such Text/)
          end.to raise_error('expected to find text matching /No such Text/ in "Text"')
        end

        it 'casts Integer to string' do
          expect do
            expect('<h1>Text</h1>').to have_text(3)
          end.to raise_error(/expected to find text "3" in "Text"/)
        end

        it 'fails if matched text count does not equal to expected count' do
          expect do
            expect('<h1>Text</h1>').to have_text('Text', count: 2)
          end.to raise_error('expected to find text "Text" 2 times but found 1 time in "Text"')
        end

        it 'fails if matched text count is less than expected minimum count' do
          expect do
            expect('<h1>Text</h1>').to have_text('Lorem', minimum: 1)
          end.to raise_error('expected to find text "Lorem" at least 1 time but found 0 times in "Text"')
        end

        it 'fails if matched text count is more than expected maximum count' do
          expect do
            expect('<h1>Text TextText</h1>').to have_text('Text', maximum: 2)
          end.to raise_error('expected to find text "Text" at most 2 times but found 3 times in "Text TextText"')
        end

        it 'fails if matched text count does not belong to expected range' do
          expect do
            expect('<h1>Text</h1>').to have_text('Text', between: 2..3)
          end.to raise_error('expected to find text "Text" between 2 and 3 times but found 1 time in "Text"')
        end
      end

      context 'with should_not' do
        it "passes if text doesn't contain a string" do
          expect('<h1>Text</h1>').not_to have_text('No such Text')
        end

        it 'passes because escapes any characters that would have special meaning in a regexp' do
          expect('<h1>Text</h1>').not_to have_text('.')
        end

        it 'fails if text contains a string' do
          expect do
            expect('<h1>Text</h1>').not_to have_text('Text')
          end.to raise_error(/expected not to find text "Text" in "Text"/)
        end
      end
    end

    context 'on a page or node' do
      before do
        session.visit('/with_html')
      end

      context 'with should' do
        it 'passes if has_text? returns true' do
          expect(session).to have_text('This is a test')
        end

        it 'passes if has_text? returns true using regexp' do
          expect(session).to have_text(/test/)
        end

        it 'can check for all text' do
          expect(session).to have_text(:all, 'Some of this text is hidden!')
        end

        it 'can check for visible text' do
          expect(session).to have_text(:visible, 'Some of this text is')
          expect(session).not_to have_text(:visible, 'Some of this text is hidden!')
        end

        it 'fails if has_text? returns false' do
          expect do
            expect(session).to have_text('No such Text')
          end.to raise_error(/expected to find text "No such Text" in "(.*)This is a test(.*)"/)
        end

        context 'with default selector CSS' do
          before { Capybara.default_selector = :css }

          after { Capybara.default_selector = :xpath }

          it 'fails if has_text? returns false' do
            expect do
              expect(session).to have_text('No such Text')
            end.to raise_error(/expected to find text "No such Text" in "(.*)This is a test(.*)"/)
          end
        end
      end

      context 'with should_not' do
        it 'passes if has_no_text? returns true' do
          expect(session).not_to have_text('No such Text')
        end

        it 'fails if has_no_text? returns false' do
          expect do
            expect(session).not_to have_text('This is a test')
          end.to raise_error(/expected not to find text "This is a test"/)
        end
      end
    end

    it 'supports compounding' do
      expect('<h1>Text</h1><h2>And</h2>').to have_text('Text').and have_text('And')
      expect('<h1>Text</h1><h2>Or</h2>').to have_text('Not here').or have_text('Or')
    end
  end

  describe 'have_link matcher' do
    let(:html) { '<a href="#">Just a link</a><a href="#">Another link</a>' }

    it 'gives proper description' do
      expect(have_link('Just a link').description).to eq('have visible link "Just a link"')
    end

    it 'passes if there is such a link' do
      expect(html).to have_link('Just a link')
    end

    it 'fails if there is no such link' do
      expect do
        expect(html).to have_link('No such Link')
      end.to raise_error(/expected to find link "No such Link"/)
    end

    it 'supports compounding' do
      expect(html).to have_link('Just a link').and have_link('Another link')
      expect(html).to have_link('Not a link').or have_link('Another link')
      expect(html).to have_no_link('Not a link').and have_link('Another link')
    end
  end

  describe 'have_title matcher' do
    it 'gives proper description' do
      expect(have_title('Just a title').description).to eq('have title "Just a title"')
    end

    context 'on a string' do
      let(:html) { '<title>Just a title</title>' }

      it 'passes if there is such a title' do
        expect(html).to have_title('Just a title')
      end

      it 'fails if there is no such title' do
        expect do
          expect(html).to have_title('No such title')
        end.to raise_error('expected "Just a title" to include "No such title"')
      end

      it "fails if title doesn't match regexp" do
        expect do
          expect(html).to have_title(/[[:upper:]]+[[:lower:]]+l{2}o/)
        end.to raise_error('expected "Just a title" to match /[[:upper:]]+[[:lower:]]+l{2}o/')
      end
    end

    context 'on a page or node' do
      it 'passes if there is such a title' do
        session.visit('/with_js')
        expect(session).to have_title('with_js')
      end

      it 'fails if there is no such title' do
        session.visit('/with_js')
        expect do
          expect(session).to have_title('No such title')
        end.to raise_error(/ to include "No such title"/)
      end

      context 'with wait' do
        before do
          session.visit('/with_js')
        end

        it 'waits if wait time is more than timeout' do
          session.click_link('Change title')
          session.using_wait_time 0 do
            expect(session).to have_title('changed title', wait: 2)
          end
        end

        it "doesn't wait if wait time is less than timeout" do
          session.click_link('Change title')
          session.using_wait_time 3 do
            expect(session).not_to have_title('changed title', wait: 0)
          end
        end
      end
    end

    it 'supports compounding' do
      expect('<title>I compound</title>').to have_title('I dont compound').or have_title('I compound')
    end
  end

  describe 'have_current_path matcher' do
    it 'gives proper description' do
      expect(have_current_path('http://www.example.com').description).to eq('have current path "http://www.example.com"')
    end

    context 'on a page or node' do
      it 'passes if there is such a current path' do
        session.visit('/with_js')
        expect(session).to have_current_path('/with_js')
      end

      it 'fails if there is no such current_path' do
        visit('/with_js')
        expect do
          expect(session).to have_current_path('/not_with_js')
        end.to raise_error(%r{to equal "/not_with_js"})
      end

      context 'with wait' do
        before do
          session.visit('/with_js')
        end

        it 'waits if wait time is more than timeout' do
          session.click_link('Change page')
          session.using_wait_time 0 do
            expect(session).to have_current_path('/with_html', wait: 2)
          end
        end

        it "doesn't wait if wait time is less than timeout" do
          session.click_link('Change page')
          session.using_wait_time 0 do
            expect(session).not_to have_current_path('/with_html')
          end
        end
      end
    end

    it 'supports compounding' do
      session.visit('/with_html')
      expect(session).to have_current_path('/not_with_html').or have_current_path('/with_html')
    end
  end

  describe 'have_button matcher' do
    let(:html) { '<button>A button</button><input type="submit" value="Another button"/>' }

    it 'gives proper description with no options' do
      expect(have_button('A button').description).to eq('have visible button "A button" that is not disabled')
    end

    it 'gives proper description with disabled :any option' do
      expect(have_button('A button', disabled: :all).description).to eq('have visible button "A button"')
    end

    it 'passes if there is such a button' do
      expect(html).to have_button('A button')
    end

    it 'fails if there is no such button' do
      expect do
        expect(html).to have_button('No such Button')
      end.to raise_error(/expected to find button "No such Button"/)
    end

    it 'supports compounding' do
      expect(html).to have_button('Not this button').or have_button('A button')
    end
  end

  describe 'have_field matcher' do
    let(:html) { '<p><label>Text field<input type="text" value="some value"/></label></p>' }

    it 'gives proper description' do
      expect(have_field('Text field').description).to eq('have visible field "Text field" that is not disabled')
    end

    it 'gives proper description for a given value' do
      expect(have_field('Text field', with: 'some value').description).to eq('have visible field "Text field" that is not disabled with value "some value"')
    end

    it 'passes if there is such a field' do
      expect(html).to have_field('Text field')
    end

    it 'passes if there is such a field with value' do
      expect(html).to have_field('Text field', with: 'some value')
    end

    it 'fails if there is no such field' do
      expect do
        expect(html).to have_field('No such Field')
      end.to raise_error(/expected to find field "No such Field"/)
    end

    it 'fails if there is such field but with false value' do
      expect do
        expect(html).to have_field('Text field', with: 'false value')
      end.to raise_error(/expected to find visible field "Text field"/)
    end

    it 'treats a given value as a string' do
      foo = Class.new do
        def to_s
          'some value'
        end
      end
      expect(html).to have_field('Text field', with: foo.new)
    end

    it 'supports compounding' do
      expect(html).to have_field('Not this one').or have_field('Text field')
    end
  end

  describe 'have_checked_field matcher' do
    let(:html) do
      '<label>it is checked<input type="checkbox" checked="checked"/></label>
      <label>unchecked field<input type="checkbox"/></label>'
    end

    it 'gives proper description' do
      expect(have_checked_field('it is checked').description).to eq('have visible field "it is checked" that is not disabled that is checked')
    end

    context 'with should' do
      it 'passes if there is such a field and it is checked' do
        expect(html).to have_checked_field('it is checked')
      end

      it 'fails if there is such a field but it is not checked' do
        expect do
          expect(html).to have_checked_field('unchecked field')
        end.to raise_error(/expected to find visible field "unchecked field"/)
      end

      it 'fails if there is no such field' do
        expect do
          expect(html).to have_checked_field('no such field')
        end.to raise_error(/expected to find field "no such field"/)
      end
    end

    context 'with should not' do
      it 'fails if there is such a field and it is checked' do
        expect do
          expect(html).not_to have_checked_field('it is checked')
        end.to raise_error(/expected not to find visible field "it is checked"/)
      end

      it 'passes if there is such a field but it is not checked' do
        expect(html).not_to have_checked_field('unchecked field')
      end

      it 'passes if there is no such field' do
        expect(html).not_to have_checked_field('no such field')
      end
    end

    it 'supports compounding' do
      expect(html).to have_checked_field('not this one').or have_checked_field('it is checked')
    end
  end

  describe 'have_unchecked_field matcher' do
    let(:html) do
      '<label>it is checked<input type="checkbox" checked="checked"/></label>
      <label>unchecked field<input type="checkbox"/></label>'
    end

    it 'gives proper description' do
      expect(have_unchecked_field('unchecked field').description).to eq('have visible field "unchecked field" that is not disabled that is not checked')
    end

    context 'with should' do
      it 'passes if there is such a field and it is not checked' do
        expect(html).to have_unchecked_field('unchecked field')
      end

      it 'fails if there is such a field but it is checked' do
        expect do
          expect(html).to have_unchecked_field('it is checked')
        end.to raise_error(/expected to find visible field "it is checked"/)
      end

      it 'fails if there is no such field' do
        expect do
          expect(html).to have_unchecked_field('no such field')
        end.to raise_error(/expected to find field "no such field"/)
      end
    end

    context 'with should not' do
      it 'fails if there is such a field and it is not checked' do
        expect do
          expect(html).not_to have_unchecked_field('unchecked field')
        end.to raise_error(/expected not to find visible field "unchecked field"/)
      end

      it 'passes if there is such a field but it is checked' do
        expect(html).not_to have_unchecked_field('it is checked')
      end

      it 'passes if there is no such field' do
        expect(html).not_to have_unchecked_field('no such field')
      end
    end

    it 'supports compounding' do
      expect(html).to have_unchecked_field('it is checked').or have_unchecked_field('unchecked field')
    end
  end

  describe 'have_select matcher' do
    let(:html) { '<label>Select Box<select></select></label>' }

    it 'gives proper description' do
      expect(have_select('Select Box').description).to eq('have visible select box "Select Box" that is not disabled')
    end

    it 'gives proper description for a given selected value' do
      expect(have_select('Select Box', selected: 'some value').description).to eq('have visible select box "Select Box" that is not disabled with "some value" selected')
    end

    it 'passes if there is such a select' do
      expect(html).to have_select('Select Box')
    end

    it 'fails if there is no such select' do
      expect do
        expect(html).to have_select('No such Select box')
      end.to raise_error(/expected to find select box "No such Select box"/)
    end

    it 'supports compounding' do
      expect(html).to have_select('Not this one').or have_select('Select Box')
    end
  end

  describe 'have_table matcher' do
    let(:html) { '<table><caption>Lovely table</caption></table>' }

    it 'gives proper description' do
      expect(have_table('Lovely table').description).to eq('have visible table "Lovely table"')
      expect(have_table('Lovely table', caption: 'my caption').description).to eq('have visible table "Lovely table" with caption "my caption"')
    end

    it 'gives proper description when :visible option passed' do
      expect(have_table('Lovely table', visible: true).description).to eq('have visible table "Lovely table"') # rubocop:disable RSpec/Capybara/VisibilityMatcher
      expect(have_table('Lovely table', visible: :hidden).description).to eq('have non-visible table "Lovely table"')
      expect(have_table('Lovely table', visible: :all).description).to eq('have table "Lovely table"')
      expect(have_table('Lovely table', visible: false).description).to eq('have table "Lovely table"') # rubocop:disable RSpec/Capybara/VisibilityMatcher
    end

    it 'passes if there is such a table' do
      expect(html).to have_table('Lovely table')
    end

    it 'fails if there is no such table' do
      expect do
        expect(html).to have_table('No such Table')
      end.to raise_error(/expected to find table "No such Table"/)
    end

    it 'supports compounding' do
      expect(html).to have_table('nope').or have_table('Lovely table')
    end
  end

  context 'compounding timing' do
    let(:session) { session }
    let(:el) { session.find(:css, '#reload-me') }

    before do
      session.visit('/with_js')
    end

    describe '#and' do
      it "should run 'concurrently'" do
        session.using_wait_time(2) do
          matcher = have_text('this is not there').and have_text('neither is this')
          expect(Benchmark.realtime do
            expect do
              expect(el).to matcher
            end.to raise_error RSpec::Expectations::ExpectationNotMetError
          end).to be_between(2, 3)
        end
      end

      it "should run 'concurrently' and retry" do
        session.click_link('reload-link')
        session.using_wait_time(2) do
          expect(Benchmark.realtime do
            expect do
              expect(el).to have_text('waiting to be reloaded').and(have_text('has been reloaded'))
            end.to raise_error RSpec::Expectations::ExpectationNotMetError, /expected to find text "waiting to be reloaded" in "has been reloaded"/
          end).to be_between(2, 3)
        end
      end

      it 'should ignore :wait options' do
        session.using_wait_time(2) do
          matcher = have_text('this is not there', wait: 5).and have_text('neither is this', wait: 6)
          expect(Benchmark.realtime do
            expect do
              expect(el).to matcher
            end.to raise_error RSpec::Expectations::ExpectationNotMetError
          end).to be_between(2, 3)
        end
      end

      it 'should work on the session' do
        session.using_wait_time(2) do
          session.click_link('reload-link')
          expect(session).to have_selector(:css, 'h1', text: 'FooBar').and have_text('has been reloaded')
        end
      end
    end

    describe '#and_then' do
      it 'should run sequentially' do
        session.click_link('reload-link')
        expect(el).to have_text('waiting to be reloaded').and_then have_text('has been reloaded')
      end
    end

    describe '#or' do
      it "should run 'concurrently'" do
        session.using_wait_time(3) do
          expect(Benchmark.realtime do
            expect(el).to have_text('has been reloaded').or have_text('waiting to be reloaded')
          end).to be < 1
        end
      end

      it 'should retry' do
        session.using_wait_time(3) do
          expect(Benchmark.realtime do
            expect do
              expect(el).to have_text('has been reloaded').or have_text('random stuff')
            end.to raise_error RSpec::Expectations::ExpectationNotMetError
          end).to be > 3
        end
      end

      it 'should ignore :wait options' do
        session.using_wait_time(2) do
          expect(Benchmark.realtime do
            expect do
              expect(el).to have_text('this is not there', wait: 10).or have_text('neither is this', wait: 15)
            end.to raise_error RSpec::Expectations::ExpectationNotMetError
          end).to be_between(2, 3)
        end
      end

      it 'should work on the session' do
        session.using_wait_time(2) do
          session.click_link('reload-link')
          expect(session).to have_selector(:css, 'h1', text: 'Not on the page').or have_text('has been reloaded')
        end
      end
    end
  end
end
# rubocop:enable RSpec/ExpectActual
