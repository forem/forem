module Badges
  class AwardYearlyClub
    YEARS = {
      1 => "d0-a0-d1-96-d1-87-d0-bd-d0-b8-d1-86-d1-8f",
      2 => "d0-94-d0-b2-d0-b0-d1-80-d0-be-d0-ba-d0-b8",
      3 => "d0-a2-d1-80-d0-b8-d1-80-d0-be-d0-ba-d0-b8",
      4 => "d0-a7-d0-be-d1-82-d0-b8-d1-80-d0-b8-d1-80-d0-be-d0-ba-d0-b8",
      5 => "d0-9f-27-d1-8f-d1-82-d0-b8-d1-80-d1-96-d1-87-d1-87-d1-",
      6 => "d0-a8-d0-b5-d1-81-d1-82-d0-b8-d1-80-d1-96-d1-87-d1-87-d1-8f",
      7 => "d0-a1-d0-b5-d0-bc-d0-b8-d1-80-d1-96-d1-87-d1-87-d1-8f",
      8 => "d0-92-d0-be-d1-81-d1-8c-d0-bc-d0-b8-d1-80-d1-96-d1-87-d1-87-d1-8f",
      9 => "d0-94-d0-b5-d0-b2-27-d1-8f-d1-82-d0-b8-d1-80-d1-96-d1-87-d1-87-d1-8f",
      10 => "d0-94-d0-b5-d1-81-d1-8f-d1-82-d0-b8-d1-80-d1-96-d1-87-d1-87-d1-8f-21",
      20 => "d0-94-d0-b2-d0-b0-d0-b4-d1-86-d1-8f-d1-82-d1-8c-d1-80-d0-be-d0-ba-d1-96-d0-b2-21"
    }.freeze

    def self.call
      new.call
    end

    def call
      total_years = Time.current.year - Settings::Community.copyright_start_year.to_i
      (1..total_years).each do |i|
        ::Badges::Award.call(
          User.registered.where(created_at: i.year.ago - 2.days...i.year.ago),
          "#{YEARS[i]}",
          generate_message(i),
        )
      end
    end

    private

    def generate_message(years)
      I18n.t("services.badges.award_yearly_club.message", community: Settings::Community.community_name, count: years)
    end
  end
end
