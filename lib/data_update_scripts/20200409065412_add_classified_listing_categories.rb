module DataUpdateScripts
  class AddClassifiedListingCategories
    CATEGORIES = {
      cfp: { cost: 1, name: "Conference CFP", rules: "Currently open for proposals, with link to form." },
      forhire: { cost: 1, name: "Available for Hire", rules: "You are available for hire." },
      collabs: { cost: 1, name: "Contributors/Collaborators Wanted", rules: "Projects looking for volunteers. Not job listings." },
      education: { cost: 1, name: "Education/Courses", rules: "Educational material and/or schools/bootcamps." },
      jobs: { cost: 25, name: "Job Listings", rules: "Companies offering employment right now." },
      mentors: { cost: 1, name: "Offering Mentorship", rules: "You are available to mentor someone." },
      products: { cost: 5, name: "Products/Tools", rules: "Must be available right now." },
      mentees: { cost: 1, name: "Seeking a Mentor", rules: "You are looking for a mentor." },
      forsale: { cost: 1, name: "Stuff for Sale", rules: "Personally owned physical items for sale." },
      events: { cost: 1, name: "Upcoming Events", rules: "In-person or online events with date included." },
      misc: { cost: 1, name: "Miscellaneous", rules: "Must not fit in any other category." }
    }.freeze

    def run
      CATEGORIES.each do |key, attributes|
        category = ClassifiedListingCategory.find_or_create_by!(attributes)
        ClassifiedListing.
          where(category: key.to_s).
          update_all(classified_listing_category_id: category.id)
      end
    end
  end
end
