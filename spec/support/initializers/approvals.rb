require "approvals/rspec"

Approvals.configure do |approvals_config|
  approvals_config.approvals_path = "#{::Rails.root}/spec/support/fixtures/approvals/"
end
