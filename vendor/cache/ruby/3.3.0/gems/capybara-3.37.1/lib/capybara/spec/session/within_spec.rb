# frozen_string_literal: true

Capybara::SpecHelper.spec '#within' do
  before do
    @session.visit('/with_scope')
  end

  context 'with CSS selector' do
    it 'should click links in the given scope' do
      @session.within(:css, '#for_bar li:first-child') do
        @session.click_link('Go')
      end
      expect(@session).to have_content('Bar')
    end

    it 'should assert content in the given scope' do
      @session.within(:css, '#for_foo') do
        expect(@session).not_to have_content('First Name')
      end
      expect(@session).to have_content('First Name')
    end

    it 'should accept additional options' do
      @session.within(:css, '#for_bar li', text: 'With Simple HTML') do
        @session.click_link('Go')
      end
      expect(@session).to have_content('Bar')
    end

    it 'should reload the node if the page is changed' do
      @session.within(:css, '#for_foo') do
        @session.visit('/with_scope_other')
        expect(@session).to have_content('Different text')
      end
    end

    it 'should reload multiple nodes if the page is changed' do
      @session.within(:css, '#for_bar') do
        @session.within(:css, 'form[action="/redirect"]') do
          @session.refresh
          expect(@session).to have_content('First Name')
        end
      end
    end

    it 'should error if the page is changed and a matching node no longer exists' do
      @session.within(:css, '#for_foo') do
        @session.visit('/')
        expect { @session.text }.to raise_error(StandardError)
      end
    end
  end

  context 'with XPath selector' do
    it 'should click links in the given scope' do
      @session.within(:xpath, "//div[@id='for_bar']//li[contains(.,'With Simple HTML')]") do
        @session.click_link('Go')
      end
      expect(@session).to have_content('Bar')
    end
  end

  context 'with the default selector' do
    it 'should use XPath' do
      @session.within("//div[@id='for_bar']//li[contains(.,'With Simple HTML')]") do
        @session.click_link('Go')
      end
      expect(@session).to have_content('Bar')
    end
  end

  context 'with Node rather than selector' do
    it 'should click links in the given scope' do
      node_of_interest = @session.find(:css, '#for_bar li', text: 'With Simple HTML')

      @session.within(node_of_interest) do
        @session.click_link('Go')
      end
      expect(@session).to have_content('Bar')
    end
  end

  context 'with the default selector set to CSS' do
    before { Capybara.default_selector = :css }

    after { Capybara.default_selector = :xpath }

    it 'should use CSS' do
      @session.within('#for_bar li', text: 'With Simple HTML') do
        @session.click_link('Go')
      end
      expect(@session).to have_content('Bar')
    end
  end

  context 'with nested scopes' do
    it 'should respect the inner scope' do
      @session.within("//div[@id='for_bar']") do
        @session.within(".//li[contains(.,'Bar')]") do
          @session.click_link('Go')
        end
      end
      expect(@session).to have_content('Another World')
    end

    it 'should respect the outer scope' do
      @session.within("//div[@id='another_foo']") do
        @session.within(".//li[contains(.,'With Simple HTML')]") do
          @session.click_link('Go')
        end
      end
      expect(@session).to have_content('Hello world')
    end
  end

  it 'should raise an error if the scope is not found on the page' do
    expect do
      @session.within("//div[@id='doesnotexist']") do
      end
    end.to raise_error(Capybara::ElementNotFound)
  end

  it 'should restore the scope when an error is raised' do
    expect do
      @session.within("//div[@id='for_bar']") do
        expect do
          expect do
            @session.within(".//div[@id='doesnotexist']") do
            end
          end.to raise_error(Capybara::ElementNotFound)
        end.not_to change { @session.has_xpath?(".//div[@id='another_foo']") }.from(false)
      end
    end.not_to change { @session.has_xpath?(".//div[@id='another_foo']") }.from(true)
  end

  it 'should fill in a field and click a button' do
    @session.within("//li[contains(.,'Bar')]") do
      @session.click_button('Go')
    end
    expect(extract_results(@session)['first_name']).to eq('Peter')
    @session.visit('/with_scope')
    @session.within("//li[contains(.,'Bar')]") do
      @session.fill_in('First Name', with: 'Dagobert')
      @session.click_button('Go')
    end
    expect(extract_results(@session)['first_name']).to eq('Dagobert')
  end

  it 'should have #within_element as an alias' do
    expect(Capybara::Session.instance_method(:within)).to eq Capybara::Session.instance_method(:within_element)
    @session.within_element(:css, '#for_foo') do
      expect(@session).not_to have_content('First Name')
    end
  end
end

Capybara::SpecHelper.spec '#within_fieldset' do
  before do
    @session.visit('/fieldsets')
  end

  it 'should restrict scope to a fieldset given by id' do
    @session.within_fieldset('villain_fieldset') do
      @session.fill_in('Name', with: 'Goldfinger')
      @session.click_button('Create')
    end
    expect(extract_results(@session)['villain_name']).to eq('Goldfinger')
  end

  it 'should restrict scope to a fieldset given by legend' do
    @session.within_fieldset('Villain') do
      @session.fill_in('Name', with: 'Goldfinger')
      @session.click_button('Create')
    end
    expect(extract_results(@session)['villain_name']).to eq('Goldfinger')
  end
end

Capybara::SpecHelper.spec '#within_table' do
  before do
    @session.visit('/tables')
  end

  it 'should restrict scope to a fieldset given by id' do
    @session.within_table('girl_table') do
      @session.fill_in('Name', with: 'Christmas')
      @session.click_button('Create')
    end
    expect(extract_results(@session)['girl_name']).to eq('Christmas')
  end

  it 'should restrict scope to a fieldset given by legend' do
    @session.within_table('Villain') do
      @session.fill_in('Name', with: 'Quantum')
      @session.click_button('Create')
    end
    expect(extract_results(@session)['villain_name']).to eq('Quantum')
  end
end
