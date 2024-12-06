# frozen_string_literal: true

# Date code pulled and adapted from:
# Ruby Cookbook by Lucas Carlson and Leonard Richardson
# Published by O'Reilly
# ISBN: 0-596-52369-6
class Date
  def feed_utils_to_gm_time
    feed_utils_to_time(new_offset, :gm)
  end

  private

  def feed_utils_to_time(dest, method)
    # Convert a fraction of a day to a number of microseconds
    usec = (dest.sec_fraction * (10**6)).to_i
    Time.send(method, dest.year, dest.month, dest.day, dest.hour, dest.min, dest.sec, usec)
  end
end
