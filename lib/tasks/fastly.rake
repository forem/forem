namespace :fastly do
  desc "Update VCL for whitelisted params on Fastly"
  task update_whitelisted_params: :environment do
    FastlyVCL::WhitelistedParams.update
  end
end
