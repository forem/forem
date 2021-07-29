module DataUpdateScripts
  class BackfillForemConsumerAppTeamId
    def run
      ConsumerApp
        .where(app_bundle: ConsumerApp::FOREM_BUNDLE, platform: :ios)
        .update(team_id: ConsumerApp::FOREM_TEAM_ID)
    end
  end
end
