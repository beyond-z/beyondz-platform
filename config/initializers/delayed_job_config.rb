Delayed::Worker.sleep_delay = 10
Delayed::Worker.max_attempts = 2
Delayed::Worker.max_run_time = 10.minutes
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.raise_signal_exceptions = :term
