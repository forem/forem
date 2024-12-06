# frozen_string_literal: true

module Faker
  class Vehicle < Base
    flexible :vehicle

    MILEAGE_MIN = 10_000
    MILEAGE_MAX = 90_000
    VIN_LETTERS = 'ABCDEFGHJKLMNPRSTUVWXYZ'
    VIN_MAP = '0123456789X'
    VIN_WEIGHTS = '8765432X098765432'
    VIN_REGEX = /^([A-HJ-NPR-Z0-9]){3}[A-HJ-NPR-Z0-9]{5}[A-HJ-NPR-Z0-9]{1}[A-HJ-NPR-Z0-9]{1}[A-HJ-NPR-Z0-]{1}[A-HJ-NPR-Z0-9]{1}\d{5}$/.freeze
    SG_CHECKSUM_WEIGHTS = [3, 14, 2, 12, 2, 11, 1].freeze
    SG_CHECKSUM_CHARS = 'AYUSPLJGDBZXTRMKHEC'

    class << self
      # Produces a random vehicle VIN number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.vin #=> "LLDWXZLG77VK2LUUF"
      #
      # @faker.version 1.6.4
      def vin
        regexify(VIN_REGEX)
      end

      # Produces a random vehicle manufacturer.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.manufacture #=> "Lamborghini"
      #
      # @faker.version 1.6.4
      def manufacture
        fetch('vehicle.manufacture')
      end

      ##
      # Produces a random vehicle make.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.make #=> "Honda"
      #
      # @faker.version 1.6.4
      def make
        fetch('vehicle.makes')
      end

      ##
      # Produces a random vehicle model.
      #
      # @param make_of_model [String] Specific valid vehicle make.
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.model #=> "A8"
      #   Faker::Vehicle.model(make_of_model: 'Toyota') #=> "Prius"
      #
      # @faker.version 1.6.4
      def model(legacy_make_of_model = NOT_GIVEN, make_of_model: '')
        warn_for_deprecated_arguments do |keywords|
          keywords << :make_of_model if legacy_make_of_model != NOT_GIVEN
        end

        return fetch("vehicle.models_by_make.#{make}") if make_of_model.empty?

        fetch("vehicle.models_by_make.#{make_of_model}")
      end

      ##
      # Produces a random vehicle make and model.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.make_and_model #=> "Dodge Charger"
      #
      # @faker.version 1.6.4
      def make_and_model
        m = make

        "#{m} #{model(make_of_model: m)}"
      end

      ##
      # Produces a random vehicle style.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.style #=> "ESi"
      #
      # @faker.version 1.6.4
      def style
        fetch('vehicle.styles')
      end

      ##
      # Produces a random vehicle color.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.color #=> "Red"
      #
      # @faker.version 1.6.4
      def color
        fetch('vehicle.colors')
      end

      ##
      # Produces a random vehicle transmission.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.transmission #=> "Automanual"
      #
      # @faker.version 1.6.4
      def transmission
        fetch('vehicle.transmissions')
      end

      ##
      # Produces a random vehicle drive type.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.drive_type #=> "4x2/2-wheel drive"
      #
      # @faker.version 1.6.4
      def drive_type
        fetch('vehicle.drive_types')
      end

      ##
      # Produces a random vehicle fuel type.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.fuel_type #=> "Diesel"
      #
      # @faker.version 1.6.4
      def fuel_type
        fetch('vehicle.fuel_types')
      end

      ##
      # Produces a random car type.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.car_type #=> "Sedan"
      #
      # @faker.version 1.6.4
      def car_type
        fetch('vehicle.car_types')
      end

      ##
      # Produces a random engine cylinder count.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.engine_size #=> 6
      #   Faker::Vehicle.engine #=> 4
      #
      # @faker.version 1.6.4
      def engine
        "#{sample(fetch_all('vehicle.doors'))} #{fetch('vehicle.cylinder_engine')}"
      end

      alias engine_size engine

      ##
      # Produces a random list of car options.
      #
      # @return [Array<String>]
      #
      # @example
      #   Faker::Vehicle.car_options #=> ["DVD System", "MP3 (Single Disc)", "Tow Package", "CD (Multi Disc)", "Cassette Player", "Bucket Seats", "Cassette Player", "Leather Interior", "AM/FM Stereo", "Third Row Seats"]
      #
      # @faker.version 1.6.4
      def car_options
        Array.new(rand(5...10)) { fetch('vehicle.car_options') }
      end

      ##
      # Produces a random list of standard specs.
      #
      # @return [Array<String>]
      #
      # @example
      #   Faker::Vehicle.standard_specs #=> ["Full-size spare tire w/aluminum alloy wheel", "Back-up camera", "Carpeted cargo area", "Silver accent IP trim finisher -inc: silver shifter finisher", "Back-up camera", "Water-repellent windshield & front door glass", "Floor carpeting"]
      #
      # @faker.version 1.6.4
      def standard_specs
        Array.new(rand(5...10)) { fetch('vehicle.standard_specs') }
      end

      ##
      # Produces a random vehicle door count.
      #
      # @return [Integer]
      #
      # @example
      #   Faker::Vehicle.doors #=> 1
      #   Faker::Vehicle.door_count #=> 3
      #
      # @faker.version 1.6.4
      def doors
        sample(fetch_all('vehicle.doors'))
      end
      alias door_count doors

      ##
      # Produces a random car year between 1 and 15 years ago.
      #
      # @return [Integer]
      #
      # @example
      #   Faker::Vehicle.year #=> 2008
      #
      # @faker.version 1.6.4
      def year
        Faker::Time.backward(days: rand_in_range(365, 5475), period: :all, format: '%Y').to_i
      end

      ##
      # Produces a random mileage/kilometrage for a vehicle.
      #
      # @param min [Integer] Specific minimum limit for mileage generation.
      # @param max [Integer] Specific maximum limit for mileage generation.
      # @return [Integer]
      #
      # @example
      #   Faker::Vehicle.mileage #=> 26961
      #   Faker::Vehicle.mileage(min: 50_000) #=> 81557
      #   Faker::Vehicle.mileage(min: 50_000, max: 250_000) #=> 117503
      #   Faker::Vehicle.kilometrage #=> 35378
      #
      # @faker.version 1.6.4
      def mileage(legacy_min = NOT_GIVEN, legacy_max = NOT_GIVEN, min: MILEAGE_MIN, max: MILEAGE_MAX)
        warn_for_deprecated_arguments do |keywords|
          keywords << :min if legacy_min != NOT_GIVEN
          keywords << :max if legacy_max != NOT_GIVEN
        end

        rand_in_range(min, max)
      end

      alias kilometrage mileage

      ##
      # Produces a random license plate number.
      #
      # @param state_abbreviation [String] Two letter state abbreviation for license plate generation.
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.license_plate #=> "DEP-2483"
      #   Faker::Vehicle.license_plate(state_abbreviation: 'FL') #=> "977 UNU"
      #
      # @faker.version 1.6.4
      def license_plate(legacy_state_abreviation = NOT_GIVEN, state_abbreviation: '')
        warn_for_deprecated_arguments do |keywords|
          keywords << :state_abbreviation if legacy_state_abreviation != NOT_GIVEN
        end

        return regexify(bothify(fetch('vehicle.license_plate'))) if state_abbreviation.empty?

        key = "vehicle.license_plate_by_state.#{state_abbreviation}"
        regexify(bothify(fetch(key)))
      end

      ##
      # Produces a random license plate number for Singapore.
      #
      # @return [String]
      #
      # @example
      #   Faker::Vehicle.singapore_license_plate #=> "SLV1854M"
      #
      # @faker.version 1.6.4
      def singapore_license_plate
        key = 'vehicle.license_plate'
        plate_number = regexify(bothify(fetch(key)))
        "#{plate_number}#{singapore_checksum(plate_number)}"
      end

      ##
      # Produces a car version
      #
      # @return [String]
      #
      # @example
      #  Faker::Vehicle.version #=> "40 TFSI Premium"
      #
      # @faker.version next
      def version
        fetch('vehicle.version')
      end

      private

      def first_eight(number)
        return number[0...8] unless number.nil?

        regexify(VIN_REGEX)
      end
      alias last_eight first_eight

      def calculate_vin_check_digit(vin)
        sum = 0

        vin.each_char.with_index do |c, i|
          n = vin_char_to_number(c).to_i
          weight = VIN_WEIGHTS[i].to_i
          sum += weight * n
        end

        mod = sum % 11
        mod == 10 ? 'X' : mod
      end

      def vin_char_to_number(char)
        index = VIN_LETTERS.chars.index(char)

        return char.to_i if index.nil?

        VIN_MAP[index]
      end

      def singapore_checksum(plate_number)
        padded_alphabets = format('%3s', plate_number[/^[A-Z]+/]).tr(' ', '-').chars
        padded_digits = format('%04d', plate_number[/\d+/]).chars.map(&:to_i)
        sum = [*padded_alphabets, *padded_digits].each_with_index.reduce(0) do |memo, (char, i)|
          value = char.is_a?(Integer) ? char : char.ord - 64
          memo + (SG_CHECKSUM_WEIGHTS[i] * value)
        end

        SG_CHECKSUM_CHARS.chars[sum % 19]
      end
    end
  end
end
