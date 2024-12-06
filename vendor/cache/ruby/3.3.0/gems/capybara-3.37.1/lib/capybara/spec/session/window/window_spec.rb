# frozen_string_literal: true

# NOTE: This file uses `sleep` to sync up parts of the tests. This is only implemented like this
# because of the methods being tested. In tests using Capybara this type of behavior should be implemented
# using Capybara provided assertions with builtin waiting behavior.

Capybara::SpecHelper.spec Capybara::Window, requires: [:windows] do
  let!(:orig_window) { @session.current_window }
  before do
    @session.visit('/with_windows')
  end

  after do
    (@session.windows - [orig_window]).each do |w|
      @session.switch_to_window w
      w.close
    end
    @session.switch_to_window(orig_window)
  end

  describe '#exists?' do
    it 'should become false after window was closed' do
      other_window = @session.window_opened_by do
        @session.find(:css, '#openWindow').click
      end

      expect do
        @session.switch_to_window other_window
        other_window.close
      end.to change(other_window, :exists?).from(true).to(false)
    end
  end

  describe '#closed?' do
    it 'should become true after window was closed' do
      other_window = @session.window_opened_by do
        @session.find(:css, '#openWindow').click
      end
      expect do
        @session.switch_to_window other_window
        other_window.close
      end.to change { other_window.closed? }.from(false).to(true)
    end
  end

  describe '#current?' do
    let(:other_window) do
      @session.window_opened_by do
        @session.find(:css, '#openWindow').click
      end
    end

    it 'should become true after switching to window' do
      expect do
        @session.switch_to_window(other_window)
      end.to change(other_window, :current?).from(false).to(true)
    end

    it 'should return false if window is closed' do
      @session.switch_to_window(other_window)
      other_window.close
      expect(other_window.current?).to be(false)
    end
  end

  describe '#close' do
    let!(:other_window) do
      @session.window_opened_by do
        @session.find(:css, '#openWindow').click
      end
    end

    it 'should switch to original window if invoked not for current window' do
      expect(@session.windows.size).to eq(2)
      expect(@session.current_window).to eq(orig_window)
      other_window.close
      expect(@session.windows.size).to eq(1)
      expect(@session.current_window).to eq(orig_window)
    end

    it 'should make subsequent invocations of other methods raise no_such_window_error if invoked for current window' do
      @session.switch_to_window(other_window)
      expect(@session.current_window).to eq(other_window)
      other_window.close
      expect do
        @session.find(:css, '#some_id')
      end.to raise_error(@session.driver.no_such_window_error)
      @session.switch_to_window(orig_window)
    end
  end

  describe '#size' do
    def win_size
      @session.evaluate_script('[window.outerWidth || window.innerWidth, window.outerHeight || window.innerHeight]')
    end

    it 'should return size of whole window', requires: %i[windows js] do
      expect(@session.current_window.size).to eq win_size
    end

    it 'should switch to original window if invoked not for current window' do
      other_window = @session.window_opened_by do
        @session.find(:css, '#openWindow').click
      end
      sleep 1
      size = @session.within_window(other_window) do
        win_size
      end
      expect(other_window.size).to eq(size)
      expect(@session.current_window).to eq(orig_window)
    end
  end

  describe '#resize_to' do
    let!(:initial_size) { @session.current_window.size }

    after do
      @session.current_window.resize_to(*initial_size)
      sleep 1
    end

    it 'should be able to resize window', requires: %i[windows js] do
      width, height = initial_size
      @session.current_window.resize_to(width - 100, height - 100)
      sleep 1
      expect(@session.current_window.size).to eq([width - 100, height - 100])
    end

    it 'should stay on current window if invoked not for current window', requires: %i[windows js] do
      other_window = @session.window_opened_by do
        @session.find(:css, '#openWindow').click
      end

      other_window.resize_to(600, 400)
      expect(@session.current_window).to eq(orig_window)

      @session.within_window(other_window) do
        expect(@session.current_window.size).to eq([600, 400])
      end
    end
  end

  describe '#maximize' do
    let! :initial_size do
      @session.current_window.size
    end

    after do
      @session.current_window.resize_to(*initial_size)
      sleep 0.5
    end

    it 'should be able to maximize window', requires: %i[windows js] do
      start_width, start_height = 400, 300
      @session.current_window.resize_to(start_width, start_height)
      sleep 0.5

      @session.current_window.maximize
      sleep 0.5 # The timing on maximize is finicky on Travis -- wait a bit for maximize to occur

      max_width, max_height = @session.current_window.size

      # maximize behavior is window manage dependant, so just make sure it increases in size
      expect(max_width).to be > start_width
      expect(max_height).to be > start_height
    end

    it 'should stay on current window if invoked not for current window', requires: %i[windows js] do
      other_window = @session.window_opened_by do
        @session.find(:css, '#openWindow').click
      end
      other_window.resize_to(400, 300)
      sleep 0.5
      other_window.maximize
      sleep 0.5 # The timing on maximize is finicky on Travis -- wait a bit for maximize to occur

      expect(@session.current_window).to eq(orig_window)
      # Maximizing the browser affects all tabs so this may not be valid in real browsers
      # expect(@session.current_window.size).to eq(initial_size)

      ow_width, ow_height = other_window.size
      expect(ow_width).to be > 400
      expect(ow_height).to be > 300
    end
  end

  describe '#fullscreen' do
    let! :initial_size do
      @session.current_window.size
    end

    after do
      @session.current_window.resize_to(*initial_size)
      sleep 1
    end

    it 'should be able to fullscreen the window' do
      expect do
        @session.current_window.fullscreen
      end.not_to raise_error
    end
  end
end
