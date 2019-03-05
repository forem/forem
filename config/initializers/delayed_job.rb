Delayed::Worker.destroy_failed_jobs = !Rails.env.development?
Delayed::Worker.sleep_delay = 60
Delayed::Worker.max_attempts = 10
Delayed::Worker.max_run_time = 30.minutes
Delayed::Worker.read_ahead = 5
# Delayed::Worker.delay_jobs = !Rails.env.test?
