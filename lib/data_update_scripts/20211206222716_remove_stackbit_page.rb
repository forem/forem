module DataUpdateScripts
  class RemoveStackbitPage
    def run
      Page.destroy_by(slug: "connecting-with-stackbit")
    end
  end
end
