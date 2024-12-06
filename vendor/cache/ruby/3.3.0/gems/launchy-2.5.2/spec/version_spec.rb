require 'spec_helper'

describe 'Launchy::VERSION' do
  it "should have a #.#.# format" do
    _(Launchy::VERSION).must_match( /\d+\.\d+\.\d+/ )
    _(Launchy::Version.to_s).must_match( /\d+\.\d+\.\d+/ )
    Launchy::Version.to_a.each do |n|
      _(n.to_i).must_be :>=, 0
    end
  end
end
