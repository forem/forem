require 'time'
require 'date'

class Time #:nodoc:
  class << self
    def mock_time
      mocked_time_stack_item = Timecop.top_stack_item
      mocked_time_stack_item.nil? ? nil : mocked_time_stack_item.time(self)
    end

    alias_method :now_without_mock_time, :now

    def now_with_mock_time
      mock_time || now_without_mock_time
    end

    alias_method :now, :now_with_mock_time

    alias_method :new_without_mock_time, :new

    def new_with_mock_time(*args)
      args.size <= 0 ? now : new_without_mock_time(*args)
    end

    ruby2_keywords :new_with_mock_time if Module.private_method_defined?(:ruby2_keywords)

    alias_method :new, :new_with_mock_time
  end
end

class Date #:nodoc:
  class << self
    def mock_date
      mocked_time_stack_item.nil? ? nil : mocked_time_stack_item.date(self)
    end

    alias_method :today_without_mock_date, :today

    def today_with_mock_date
      mock_date || today_without_mock_date
    end

    alias_method :today, :today_with_mock_date

    alias_method :strptime_without_mock_date, :strptime

    def strptime_with_mock_date(str = '-4712-01-01', fmt = '%F', start = Date::ITALY)
      #If date is not valid the following line raises
      Date.strptime_without_mock_date(str, fmt, start)

      d = Date._strptime(str, fmt)
      now = Time.now.to_date
      year = d[:year] || d[:cwyear] || now.year
      mon = d[:mon] || now.mon
      if d.keys == [:year]
        Date.new(year, 1, 1, start)
      elsif d[:mday]
        Date.new(year, mon, d[:mday], start)
      elsif d[:yday]
        Date.new(year, 1, 1, start).next_day(d[:yday] - 1)
      elsif d[:cwyear] || d[:cweek] || d[:wnum0] || d[:wnum1] || d[:wday] || d[:cwday]
        week = d[:cweek] || d[:wnum1] || d[:wnum0] || now.strftime('%W').to_i
        if d[:wnum0] #Week of year where week starts on sunday
          if d[:cwday] #monday based day of week
            Date.strptime_without_mock_date("#{year} #{week} #{d[:cwday]}", '%Y %U %u', start)
          else
            Date.strptime_without_mock_date("#{year} #{week} #{d[:wday] || 0}", '%Y %U %w', start)
          end
        else #Week of year where week starts on monday
          if d[:wday] #sunday based day of week
            Date.strptime_without_mock_date("#{year} #{week} #{d[:wday]}", '%Y %W %w', start)
          else
            Date.strptime_without_mock_date("#{year} #{week} #{d[:cwday] || 1}", '%Y %W %u', start)
          end
        end
      elsif d[:seconds]
        Time.at(d[:seconds]).to_date
      else
        Date.new(year, mon, 1, start)
      end
    end

    alias_method :strptime, :strptime_with_mock_date

    def parse_with_mock_date(*args)
      parsed_date = parse_without_mock_date(*args)
      return parsed_date unless mocked_time_stack_item
      date_hash = Date._parse(*args)

      case
      when date_hash[:year] && date_hash[:mon]
        parsed_date
      when date_hash[:mon] && date_hash[:mday]
        Date.new(mocked_time_stack_item.year, date_hash[:mon], date_hash[:mday])
      when date_hash[:mday]
        Date.new(mocked_time_stack_item.year, mocked_time_stack_item.month, date_hash[:mday])
      when date_hash[:wday]
        closest_wday(date_hash[:wday])
      else
        parsed_date + mocked_time_stack_item.travel_offset_days
      end
    end

    alias_method :parse_without_mock_date, :parse
    alias_method :parse, :parse_with_mock_date

    def mocked_time_stack_item
      Timecop.top_stack_item
    end

    def closest_wday(wday)
      today = Date.today
      result = today - today.wday
      result += 1 until wday == result.wday
      result
    end
  end
end

class DateTime #:nodoc:
  class << self
    def mock_time
      mocked_time_stack_item.nil? ? nil : mocked_time_stack_item.datetime(self)
    end

    def now_with_mock_time
      mock_time || now_without_mock_time
    end

    alias_method :now_without_mock_time, :now

    alias_method :now, :now_with_mock_time

    def parse_with_mock_date(*args)
      parsed_date = parse_without_mock_date(*args)
      return parsed_date unless mocked_time_stack_item
      date_hash = DateTime._parse(*args)

      case
      when date_hash[:year] && date_hash[:mon]
        parsed_date
      when date_hash[:mon] && date_hash[:mday]
        DateTime.new(mocked_time_stack_item.year, date_hash[:mon], date_hash[:mday])
      when date_hash[:mday]
        DateTime.new(mocked_time_stack_item.year, mocked_time_stack_item.month, date_hash[:mday])
      when date_hash[:wday]
        Date.closest_wday(date_hash[:wday]).to_datetime
      else
        parsed_date + mocked_time_stack_item.travel_offset_days
      end
    end

    alias_method :parse_without_mock_date, :parse
    alias_method :parse, :parse_with_mock_date

    def mocked_time_stack_item
      Timecop.top_stack_item
    end
  end
end
