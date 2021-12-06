module DataUpdateScripts
  class RemoveStackbitPage
    def run
      Page.find_by(slug: "connecting-with-stackbit")&.destroy
    end
  end
end
