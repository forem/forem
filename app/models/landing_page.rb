class LandingPage
  class << self
    def exists?
      Page.exists?(landing_page: true)
    end

    def id
      page&.id
    end

    def get
      page
    end

    def set(page)
      Page.transaction do
        Page.where(landing_page: true).update_all(landing_page: false)
        page.update(landing_page: true)
      end
    end

    def remove
      page&.update(landing_page: false)
    end

    private

    def page
      Page.find_by(landing_page: true)
    end
  end
end
