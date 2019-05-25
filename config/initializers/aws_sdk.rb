AWS_LAMBDA = if Rails.env.production?
               Aws::Lambda::Client.new(
                 region: ApplicationConfig["AWS_DEFAULT_REGION"],
                 access_key_id: ApplicationConfig["AWS_SDK_KEY"],
                 secret_access_key: ApplicationConfig["AWS_SDK_SECRET"],
               )
             else
               Aws::FakeClient.new
             end
