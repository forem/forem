# frozen_string_literal: true

# rubocop:disable RSpec/MultipleDescribes

require 'spec_helper'

RSpec.describe 'capybara/rspec' do
  context 'Feature', type: :feature do
    it 'should include Capybara in rspec' do
      visit('/foo')
      expect(page.body).to include('Another World')
    end

    it 'should include RSpec matcher proxies' do
      expect(self.class.ancestors).to include Capybara::RSpecMatcherProxies
    end

    context 'resetting session' do
      it 'sets a cookie in one example...' do
        visit('/set_cookie')
        expect(page.body).to include('Cookie set to test_cookie')
      end

      it '...then it is not available in the next' do
        visit('/get_cookie')
        expect(page.body).not_to include('test_cookie')
      end
    end

    context 'setting the current driver' do
      it 'sets the current driver in one example...' do
        Capybara.current_driver = :selenium
      end

      it '...then it has returned to the default in the next example' do
        expect(Capybara.current_driver).to eq(:rack_test)
      end
    end

    it 'switches to the javascript driver when giving it as metadata', js: true do
      expect(Capybara.current_driver).to eq(Capybara.javascript_driver)
    end

    it 'switches to the given driver when giving it as metadata', driver: :culerity do
      expect(Capybara.current_driver).to eq(:culerity)
    end

    describe '#all' do
      it 'allows access to the Capybara finder' do
        visit('/with_html')
        found = all(:css, 'h2') { |element| element[:class] == 'head' }
        expect(found.size).to eq(5)
      end

      it 'allows access to the RSpec matcher' do
        visit('/with_html')
        strings = %w[test1 test2]
        expect(strings).to all(be_a(String))
      end
    end

    describe '#within' do
      it 'allows access to the Capybara scoper' do
        visit('/with_html')
        expect do
          within(:css, '#does_not_exist') { click_link 'Go to simple' }
        end.to raise_error(Capybara::ElementNotFound)
      end

      it 'allows access to the RSpec matcher' do
        visit('/with_html')
        # This reads terribly, but must call #within
        expect(find(:css, 'span.number').text.to_i).to within(1).of(41)
      end
    end
  end

  context 'Type: Other', type: :other do
    context 'when RSpec::Matchers is included after Capybara::DSL' do
      let(:test_class_instance) do
        Class.new do
          include Capybara::DSL
          include RSpec::Matchers
        end.new
      end

      describe '#all' do
        it 'allows access to the Capybara finder' do
          test_class_instance.visit('/with_html')
          expect(test_class_instance.all(:css, 'h2.head').size).to eq(5)
        end

        it 'allows access to the RSpec matcher' do
          test_class_instance.visit('/with_html')
          strings = %w[test1 test2]
          expect(strings).to test_class_instance.all(be_a(String))
        end
      end

      describe '#within' do
        it 'allows access to the Capybara scoper' do
          test_class_instance.visit('/with_html')
          expect do
            test_class_instance.within(:css, '#does_not_exist') { test_class_instance.click_link 'Go to simple' }
          end.to raise_error(Capybara::ElementNotFound)
        end

        it 'allows access to the RSpec matcher' do
          test_class_instance.visit('/with_html')
          # This reads terribly, but must call #within
          expect(test_class_instance.find(:css, 'span.number').text.to_i).to test_class_instance.within(1).of(41)
        end
      end

      context 'when `match_when_negated` is not defined in a matcher' do
        before do
          RSpec::Matchers.define :only_match_matcher do |expected|
            match do |actual|
              !(actual ^ expected)
            end
          end
        end

        it 'can be called with `not_to`' do
          # This test is for a bug in jruby where `super` isn't defined correctly - https://github.com/jruby/jruby/issues/4678
          # Reported in https://github.com/teamcapybara/capybara/issues/2115
          test_class_instance.instance_eval do
            expect do
              expect(true).not_to only_match_matcher(false) # rubocop:disable RSpec/ExpectActual
            end.not_to raise_error
          end
        end
      end
    end

    it 'should not include Capybara' do
      expect { visit('/') }.to raise_error(NoMethodError)
    end
  end
end

feature 'Feature DSL' do
  scenario 'is pulled in' do
    visit('/foo')
    expect(page.body).to include('Another World')
  end
end

# rubocop:enable RSpec/MultipleDescribes
