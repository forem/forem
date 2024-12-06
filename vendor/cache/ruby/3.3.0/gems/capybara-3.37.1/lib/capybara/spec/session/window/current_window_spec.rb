# frozen_string_literal: true

Capybara::SpecHelper.spec '#current_window', requires: [:windows] do
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

  it 'should return window' do
    expect(@session.current_window).to be_instance_of(Capybara::Window)
  end

  it 'should be modified by switching to another window' do
    window = @session.window_opened_by { @session.find(:css, '#openWindow').click }

    expect do
      @session.switch_to_window(window)
    end.to change { @session.current_window }.from(@window).to(window)
  end
end
