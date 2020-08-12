Rails.application.reloader.to_prepare do
  AWS_LAMBDA = if Rails.env.production?
                 Aws::Lambda::Client.new(
                   region: ApplicationConfig["AWS_DEFAULT_REGION"],
                   access_key_id: ApplicationConfig["AWS_SDK_KEY"],
                   secret_access_key: ApplicationConfig["AWS_SDK_SECRET"],
                 )
               else
                 # Fake Aws::Lambda::Client
                 Class.new do
                   def invoke(*)
                     # rubocop:disable Performance/OpenStruct
                     OpenStruct.new(payload: [{ body: { message: 0 }.to_json }.to_json])
                     # rubocop:enable Performance/OpenStruct
                   end
                 end.new
               end
end
