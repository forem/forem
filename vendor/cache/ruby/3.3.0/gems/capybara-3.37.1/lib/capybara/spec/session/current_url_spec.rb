# frozen_string_literal: true

require 'capybara/spec/test_app'

Capybara::SpecHelper.spec '#current_url, #current_path, #current_host' do
  before :all do # rubocop:disable RSpec/BeforeAfterAll
    @servers = Array.new(2) { Capybara::Server.new(TestApp.new).boot }
    # sanity check
    expect(@servers[0].port).not_to eq(@servers[1].port) # rubocop:disable RSpec/ExpectInHook
    expect(@servers.map(&:port)).not_to include 80 # rubocop:disable RSpec/ExpectInHook
  end

  def bases
    @servers.map { |s| "http://#{s.host}:#{s.port}" }
  end

  def should_be_on(server_index, path = '/host', scheme = 'http')
    # Check that we are on /host on the given server
    s = @servers[server_index]

    expect(@session).to have_current_path("#{scheme}://#{s.host}:#{s.port}#{path}", url: true)

    expect(@session.current_url.chomp('?')).to eq("#{scheme}://#{s.host}:#{s.port}#{path}")
    expect(@session.current_host).to eq("#{scheme}://#{s.host}") # no port
    expect(@session.current_path).to eq(path.split('#')[0])
    # Server should agree with us
    expect(@session).to have_content("Current host is #{scheme}://#{s.host}:#{s.port}") if path == '/host'
  end

  def visit_host_links
    @session.visit("#{bases[0]}/host_links?absolute_host=#{bases[1]}")
  end

  it 'is affected by visiting a page directly' do
    @session.visit("#{bases[0]}/host")
    should_be_on 0
  end

  it 'returns to the app host when visiting a relative url' do
    Capybara.app_host = bases[1]
    @session.visit("#{bases[0]}/host")
    should_be_on 0
    @session.visit('/host')
    should_be_on 1
    Capybara.app_host = nil
  end

  it 'is affected by setting Capybara.app_host' do
    Capybara.app_host = bases[0]
    @session.visit('/host')
    should_be_on 0
    Capybara.app_host = bases[1]
    @session.visit('/host')
    should_be_on 1
    Capybara.app_host = nil
  end

  it 'is unaffected by following a relative link' do
    visit_host_links
    @session.click_link('Relative Host')
    should_be_on 0
  end

  it 'is affected by following an absolute link' do
    visit_host_links
    @session.click_link('Absolute Host')
    should_be_on 1
  end

  it 'is unaffected by posting through a relative form' do
    visit_host_links
    @session.click_button('Relative Host')
    should_be_on 0
  end

  it 'is affected by posting through an absolute form' do
    visit_host_links
    @session.click_button('Absolute Host')
    should_be_on 1
  end

  it 'is affected by following a redirect' do
    @session.visit("#{bases[0]}/redirect")
    should_be_on 0, '/landed'
  end

  it 'maintains fragment' do
    @session.visit("#{bases[0]}/redirect#fragment")
    should_be_on 0, '/landed#fragment'
  end

  it 'redirects to a fragment' do
    @session.visit("#{bases[0]}/redirect_with_fragment")
    should_be_on 0, '/landed#with_fragment'
  end

  it 'is affected by pushState', requires: [:js] do
    @session.visit('/with_js')
    @session.execute_script("window.history.pushState({}, '', '/pushed')")
    expect(@session.current_path).to eq('/pushed')
  end

  it 'is affected by replaceState', requires: [:js] do
    @session.visit('/with_js')
    @session.execute_script("window.history.replaceState({}, '', '/replaced')")
    expect(@session.current_path).to eq('/replaced')
  end

  it "doesn't raise exception on a nil current_url", requires: [:driver] do
    allow(@session.driver).to receive(:current_url).and_return(nil)
    @session.visit('/')
    expect { @session.current_url }.not_to raise_exception
    expect { @session.current_path }.not_to raise_exception
  end

  context 'within iframe', requires: [:frames] do
    it 'should get the url of the top level browsing context' do
      @session.visit('/within_frames')
      expect(@session.current_url).to match(/within_frames\z/)
      @session.within_frame('frameOne') do
        expect(@session.current_url).to match(/within_frames\z/)
      end
    end
  end
end
