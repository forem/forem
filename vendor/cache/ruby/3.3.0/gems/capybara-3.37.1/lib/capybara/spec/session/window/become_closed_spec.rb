# frozen_string_literal: true

Capybara::SpecHelper.spec '#become_closed', requires: %i[windows js] do
  let!(:window) { @session.current_window }
  let(:other_window) do
    @session.window_opened_by do
      @session.find(:css, '#openWindow').click
    end
  end

  before do
    @session.visit('/with_windows')
  end

  after do
    @session.document.synchronize(5, errors: [Capybara::CapybaraError]) do
      raise Capybara::CapybaraError if @session.windows.size != 1
    end
    @session.switch_to_window(window)
  end

  context 'with :wait option' do
    it 'should wait if value of :wait is more than timeout' do
      @session.within_window other_window do
        @session.execute_script('setTimeout(function(){ window.close(); }, 500);')
      end
      Capybara.using_wait_time 0.1 do
        expect(other_window).to become_closed(wait: 5)
      end
    end

    it 'should raise error if value of :wait is less than timeout' do
      @session.within_window other_window do
        @session.execute_script('setTimeout(function(){ window.close(); }, 1000);')
      end
      Capybara.using_wait_time 2 do
        expect do
          expect(other_window).to become_closed(wait: 0.2)
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /\Aexpected #<Window @handle=".+"> to become closed after 0.2 seconds\Z/)
      end
    end
  end

  context 'without :wait option' do
    it 'should wait if value of default_max_wait_time is more than timeout' do
      @session.within_window other_window do
        @session.execute_script('setTimeout(function(){ window.close(); }, 500);')
      end
      Capybara.using_wait_time 5 do
        expect(other_window).to become_closed
      end
    end

    it 'should raise error if value of default_max_wait_time is less than timeout' do
      @session.within_window other_window do
        @session.execute_script('setTimeout(function(){ window.close(); }, 900);')
      end
      Capybara.using_wait_time 0.4 do
        expect do
          expect(other_window).to become_closed
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /\Aexpected #<Window @handle=".+"> to become closed after 0.4 seconds\Z/)
      end
    end
  end

  context 'with not_to' do
    it "should not raise error if window doesn't close before default_max_wait_time" do
      @session.within_window other_window do
        @session.execute_script('setTimeout(function(){ window.close(); }, 1000);')
      end
      Capybara.using_wait_time 0.3 do
        expect do
          expect(other_window).not_to become_closed
        end.not_to raise_error
      end
    end

    it 'should raise error if window closes before default_max_wait_time' do
      @session.within_window other_window do
        @session.execute_script('setTimeout(function(){ window.close(); }, 700);')
      end
      Capybara.using_wait_time 3.1 do
        expect do
          expect(other_window).not_to become_closed
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /\Aexpected #<Window @handle=".+"> not to become closed after 3.1 seconds\Z/)
      end
    end
  end
end
