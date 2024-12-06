namespace :js do
  desc "Make a js file with all rails route URL helpers"
  task routes: :environment do
    require "js-routes"
    JsRoutes.generate!
  end

  namespace :routes do
    desc "Make a js file with all rails route URL helpers and typescript definitions for them"
    task typescript: "js:routes" do
      JsRoutes.definitions!
    end
  end
end
