# frozen_string_literal: true

Capybara::SpecHelper.spec '#accept_alert', requires: [:modals] do
  before do
    @session.visit('/with_js')
  end

  it 'should accept the alert' do
    @session.accept_alert do
      @session.click_link('Open alert')
    end
    expect(@session).to have_xpath("//a[@id='open-alert' and @opened='true']")
  end

  it 'should accept the alert if the text matches' do
    @session.accept_alert 'Alert opened' do
      @session.click_link('Open alert')
    end
    expect(@session).to have_xpath("//a[@id='open-alert' and @opened='true']")
  end

  it 'should accept the alert if text contains "special" Regex characters' do
    @session.accept_alert 'opened [*Yay?*]' do
      @session.click_link('Open alert')
    end
    expect(@session).to have_xpath("//a[@id='open-alert' and @opened='true']")
  end

  it 'should accept the alert if the text matches a regexp' do
    @session.accept_alert(/op.{2}ed/) do
      @session.click_link('Open alert')
    end
    expect(@session).to have_xpath("//a[@id='open-alert' and @opened='true']")
  end

  it 'should not accept the alert if the text doesnt match' do
    expect do
      @session.accept_alert 'Incorrect Text' do
        @session.click_link('Open alert')
      end
    end.to raise_error(Capybara::ModalNotFound)
  end

  it 'should return the message presented' do
    message = @session.accept_alert do
      @session.click_link('Open alert')
    end
    expect(message).to eq('Alert opened [*Yay?*]')
  end

  it 'should handle the alert if the page changes' do
    @session.accept_alert do
      @session.click_link('Alert page change')
      sleep 1 # ensure page change occurs before the accept_alert block exits
    end
    expect(@session).to have_current_path('/with_html', wait: 5)
  end

  context 'with an asynchronous alert' do
    it 'should accept the alert' do
      @session.accept_alert do
        @session.click_link('Open delayed alert')
      end
      expect(@session).to have_xpath("//a[@id='open-delayed-alert' and @opened='true']")
    end

    it 'should return the message presented' do
      message = @session.accept_alert do
        @session.click_link('Open delayed alert')
      end
      expect(message).to eq('Delayed alert opened')
    end

    it 'should allow to adjust the delay' do
      @session.accept_alert wait: 10 do
        @session.click_link('Open slow alert')
      end
      expect(@session).to have_xpath("//a[@id='open-slow-alert' and @opened='true']")
    end
  end
end
