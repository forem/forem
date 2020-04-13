namespace :fastly do
  desc "Update VCL for whitelisted params on Fastly"
  task update_whitelisted_params: :environment do
    unless Rails.env.production?
      puts "Will NOT update Fastly outside of production"
      exit
    end

    FastlyVCL::WhitelistedParams.update
  end
end
