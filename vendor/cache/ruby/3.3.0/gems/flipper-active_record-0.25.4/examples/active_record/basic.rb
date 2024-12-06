require_relative "./ar_setup"

# Requires the flipper-active_record gem to be installed.
require 'flipper/adapters/active_record'

Flipper[:stats].enable

if Flipper[:stats].enabled?
  puts "Enabled!"
else
  puts "Disabled!"
end

Flipper[:stats].disable

if Flipper[:stats].enabled?
  puts "Enabled!"
else
  puts "Disabled!"
end
