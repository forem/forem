require "pathname"
CLI = Pathname.new(File.dirname(__FILE__)).join("../../exe/cypress-rails")

desc "Initialize cypress.json"
task :"cypress:init" do
  system "#{CLI} init"
end

desc "Open interactive Cypress app for developing tests"
task :"cypress:open" do
  trap("SIGINT") {} # avoid traceback
  system "#{CLI} open"
end

desc "Run Cypress tests headlessly"
task :"cypress:run" do
  abort unless system "#{CLI} run"
end

desc "Run Cypress tests with knapsack"
task :"cypress:run_knapsack" do
  abort unless system "#{CLI} run_knapsack"
end
