module DataUpdateScripts
  class BackfillForemConsumerAppTeamId
    def run
      forem_app = ConsumerApps::FindOrCreateByQuery.call(app_bundle: ConsumerApp::FOREM_BUNDLE, platform: :ios)
      forem_app.team_id = "R9SWHSQNV8"
      forem_app.save
    end
  end
end
