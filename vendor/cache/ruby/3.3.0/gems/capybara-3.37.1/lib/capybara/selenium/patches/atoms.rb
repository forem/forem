# frozen_string_literal: true

module CapybaraAtoms
private

  def read_atom(function)
    @atoms ||= Hash.new do |hash, key|
      hash[key] = begin
        File.read(File.expand_path("../../atoms/#{key}.min.js", __FILE__))
      rescue Errno::ENOENT
        super
      end
    end
    @atoms[function]
  end
end

::Selenium::WebDriver::Remote::Bridge.prepend CapybaraAtoms unless ENV['DISABLE_CAPYBARA_SELENIUM_OPTIMIZATIONS']
