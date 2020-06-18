desc "Print app domain without port"

task app_domain: :environment do
  puts ApplicationConfig.app_domain_no_port
end
