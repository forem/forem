# rubocop:disable Rails/Output

class Seeder
  def initialize
    if Rails.env.production?
      puts "Can't run seeds in production"

      # rubocop:disable Rails/Exit
      exit 1
      # rubocop:enable Rails/Exit
    end

    @counter = 0
  end

  # Used when the block is idempotent by itself and needs no further checks.
  def create(message)
    @counter += 1
    puts "  #{@counter}. #{message}."
    yield
  end

  def create_if_none(klass, count = nil)
    @counter += 1
    plural = klass.name.pluralize

    if klass.none?
      message = ["Creating", count, plural].compact.join(" ")
      puts "  #{@counter}. #{message}."
      yield
    else
      puts "  #{@counter}. #{plural} already exist. Skipping."
    end
  end

  def create_if_doesnt_exist(klass, attribute_name, attribute_value)
    record = klass.find_by("#{attribute_name}": attribute_value)
    if record.nil?
      puts "  #{klass} with #{attribute_name} = #{attribute_value} not found, proceeding..."
      yield
    else
      puts "  #{klass} with #{attribute_name} = #{attribute_value} found, skipping."
    end
  end
end

# rubocop:enable Rails/Output
