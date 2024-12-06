lib = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'libhoney'

# replace this with yours from https://ui.honeycomb.com/account
writekey = '7aefa39399a474bd9f414a8e3f8d9691'
dataset  = 'factorial'

def factorial(number)
  return -1 * factorial(abs(number)) if number.negative?
  return 1 if number.zero?

  number * factorial(number - 1)
end

# run factorial. libh_builder comes with some fields already populated
# (namely, "version", "num_threads", and "range")
def run_factorial(low, high, libh_builder)
  (low..high).each do |i|
    event = libh_builder.event
    event.metadata = { fn: 'run_factorial', i: i }

    event.with_timer('factorial') do
      result = factorial(10 + i)
      event.add_field('retval', result)
    end

    event.send
  end
end

libhoney = Libhoney::Client.new(writekey: writekey,
                                dataset: dataset)

Thread.new do
  begin
    loop do
      response = libhoney.responses.pop
      break if response.nil?

      puts "Sent: Event with metadata #{response.metadata} in #{response.duration * 1000}ms."
      puts "Got:  Response code #{response.status_code}"
      puts "      #{response.error.class}: #{response.error}" if response.error
      puts
    end
  rescue StandardError => e
    puts "#{e.class} in response reader thread: #{e}"
  end
end

# attach fields to top-level instance
libhoney.add_field('version', '3.4.5')

a_proc = proc { Thread.list.select { |thread| thread.status == 'run' }.count }
libhoney.add_dynamic_field('num_threads', a_proc)

event = libhoney.event
event.metadata = { fn: 'work_thread' }
event.add_field('start_time', Time.now.iso8601(3))
event.with_timer 'run_fact_low_dur_ms' do
  run_factorial(1, 20, libhoney.builder(range: 'low'))
end
event.with_timer 'run_fact_high_dur_ms' do
  run_factorial(31, 40, libhoney.builder(range: 'high'))
end
event.add_field('end_time', Time.now.iso8601(3))
# sends an event with "version", "num_threads", "start_time", "end_time",
# "run_fact_low_dur_ms", "run_fact_high_dur_ms"
event.send

libhoney.close
