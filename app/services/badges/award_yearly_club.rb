module Badges
  class AwardYearlyClub
    YEARS = {
      1 => "one",
      2 => "two",
      3 => "three",
      4 => "four",
      5 => "five",
      6 => "six",
      7 => "seven"
    }.freeze

    MESSAGE_TEMPLATE =
      "Happy #{SiteConfig.community_name} birthday! " \
      "Can you believe it's been %<years>d %<noun>s already?!".freeze

    def self.call
      new.call
    end

    def call
      total_years = Time.current.year - SiteConfig.community_copyright_start_year.to_i
      (1..total_years).each do |i|
        ::Badges::Award.call(
          User.registered.where(created_at: i.year.ago - 2.days...i.year.ago),
          "#{YEARS[i]}-year-club",
          generate_message(i),
        )
      end
    end

    private

    def generate_message(years)
      format(MESSAGE_TEMPLATE, years: years, noun: "year".pluralize(years))
    end
  end
end
