namespace :fastly do
  desc "Update VCL for whitelisted params on Fastly"
  task update_whitelisted_params: :environment do
    if ApplicationConfig["FASTLY_API_KEY"].blank? || ApplicationConfig["FASTLY_SERVICE_ID"].blank?
      puts "Fastly not configured. Please set FASTLY_API_KEY and FAASTLY_SERVICE_ID in your environment."
      exit
    end

    FastlyVCL::WhitelistedParams.update
  end
end
