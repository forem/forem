# frozen_string_literal: true

Capybara::SpecHelper.spec '#open_new_window', requires: [:windows] do
  before do
    @window = @session.current_window
    @session.visit('/with_windows')
  end

  after do
    (@session.windows - [@window]).each do |w|
      @session.switch_to_window w
      w.close
    end
    @session.switch_to_window(@window)
  end

  it 'should open new window with blank url and title' do
    window = @session.open_new_window
    @session.switch_to_window(window)
    expect(@session.title).to satisfy('be a blank title') { |title| ['', 'about:blank'].include? title }
    expect(@session.current_url).to eq('about:blank')
  end

  it 'should open window with changeable content' do
    window = @session.open_new_window
    @session.within_window window do
      @session.visit '/with_html'
      expect(@session).to have_css('#first')
    end
  end
end
