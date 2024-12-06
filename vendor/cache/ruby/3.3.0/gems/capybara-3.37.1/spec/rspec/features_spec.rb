# frozen_string_literal: true

# rubocop:disable RSpec/MultipleDescribes

require 'spec_helper'
require 'capybara/rspec'

# rubocop:disable RSpec/InstanceVariable
RSpec.configuration.before(:each, file_path: './spec/rspec/features_spec.rb') do
  @in_filtered_hook = true
end

feature "Capybara's feature DSL" do
  background do
    @in_background = true
  end

  scenario 'includes Capybara' do
    visit('/')
    expect(page).to have_content('Hello world!')
  end

  scenario 'preserves description' do |ex|
    expect(ex.metadata[:full_description])
      .to eq("Capybara's feature DSL preserves description")
  end

  scenario 'allows driver switching', driver: :selenium do
    expect(Capybara.current_driver).to eq(:selenium)
  end

  scenario 'runs background' do
    expect(@in_background).to be_truthy
  end

  scenario 'runs hooks filtered by file path' do
    expect(@in_filtered_hook).to be_truthy
  end

  scenario "doesn't pollute the Object namespace" do
    expect(Object.new).not_to respond_to(:feature)
  end

  feature 'nested features' do
    scenario 'work as expected' do
      visit '/'
      expect(page).to have_content 'Hello world!'
    end

    scenario 'are marked in the metadata as capybara_feature' do |ex|
      expect(ex.metadata[:capybara_feature]).to be_truthy
    end

    scenario 'have a type of :feature' do |ex|
      expect(ex.metadata[:type]).to eq :feature
    end
  end
end
# rubocop:enable RSpec/InstanceVariable

feature 'given and given! aliases to let and let!' do
  given(:value) { :available }
  given!(:value_in_background) { :available }

  background do
    expect(value_in_background).to be(:available)
  end

  scenario 'given and given! work as intended' do
    expect(value).to be(:available)
    expect(value_in_background).to be(:available)
  end
end

feature "Capybara's feature DSL with driver", driver: :culerity do
  scenario 'switches driver' do
    expect(Capybara.current_driver).to eq(:culerity)
  end
end

# rubocop:disable RSpec/RepeatedExample
xfeature 'if xfeature aliases to pending then' do
  scenario "this should be 'temporarily disabled with xfeature'" do
    # dummy
  end

  scenario "this also should be 'temporarily disabled with xfeature'" do
    # dummy
  end
end

ffeature 'if ffeature aliases focused tag then' do # rubocop:disable RSpec/Focus
  scenario 'scenario inside this feature has metatag focus tag' do |example|
    expect(example.metadata[:focus]).to be true
  end

  scenario 'other scenarios also has metatag focus tag' do |example|
    expect(example.metadata[:focus]).to be true
  end
end
# rubocop:enable RSpec/RepeatedExample, RSpec/MultipleDescribes
