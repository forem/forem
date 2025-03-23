require "httparty"
require "json"

namespace :sidekiq do
  desc "Scale Heroku workers based on Sidekiq queue size"
  task scale_workers: :environment do
    # Environment variables
    heroku_api_key = ENV.fetch("HEROKU_API_KEY", nil)
    heroku_app_name = ENV.fetch("HEROKU_APP_NAME", nil)
    process_type = "sidekiq_worker" # Update this to match your Procfile process name
    min_workers = ENV.fetch("MIN_WORKERS", 1).to_i
    max_workers = ENV.fetch("MAX_WORKERS", 10).to_i
    queue_thresholds = ENV.fetch("QUEUE_THRESHOLDS", "20,100").split(",").map(&:to_i)

    # Get Sidekiq queue size
    queue_size = Sidekiq::Queue.all.map(&:size).sum
    puts "Current Sidekiq queue size: #{queue_size}"

    # Determine desired worker count
    desired_workers = case queue_size
                      when 0..queue_thresholds[0] then min_workers
                      when queue_thresholds[0] + 1..queue_thresholds[1] then (max_workers / 2).ceil
                      else max_workers
                      end

    puts "Desired worker count: #{desired_workers}"

    # Heroku API URL
    formation_url = "https://api.heroku.com/apps/#{heroku_app_name}/formation/#{process_type}"

    # Get current worker count
    response = HTTParty.get(
      formation_url,
      headers: {
        "Authorization" => "Bearer #{heroku_api_key}",
        "Accept" => "application/vnd.heroku+json; version=3"
      }
    )
    if response.code != 200
      puts "Error fetching worker info: #{response.body}"
      exit 1
    end

    current_worker_count = JSON.parse(response.body)["quantity"]
    puts "Current worker count: #{current_worker_count}"

    # Scale workers if necessary
    if current_worker_count != desired_workers
      puts "Scaling workers to #{desired_workers}..."
      update_response = HTTParty.patch(
        formation_url,
        headers: {
          "Authorization" => "Bearer #{heroku_api_key}",
          "Content-Type" => "application/json",
          "Accept" => "application/vnd.heroku+json; version=3"
        },
        body: { quantity: desired_workers }.to_json
      )

      if update_response.code == 200
        puts "Successfully scaled workers to #{desired_workers}."
      else
        puts "Error scaling workers: #{update_response.body}"
      end
    else
      puts "No scaling needed."
    end
  rescue StandardError => e
    puts "Error: #{e.message}"
  end
end
