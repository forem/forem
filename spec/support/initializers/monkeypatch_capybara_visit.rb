# module Capybara
#   class Session
#     def visit(visit_uri)
#       success = false
#       tries = 0
#       begin
#         until success or tries == 3
#           tries += 1
#           super(visit_uri)
#           success = true
#         end
#       rescue Pundit::NotAuthorizedError
#         Rails.logger.error("try #{tries} in visiting")
#       end
#     end
#   end
# end
module MonkeypatchSession
  def visit(visit_uri)
    success = false
    tries = 0
    begin
      until success || (tries == 3)
        Rails.logger.error("in visit")
        tries += 1
        super(visit_uri)
        success = true
      end
    rescue Pundit::NotAuthorizedError
      Rails.logger.error("try #{tries} in visiting")
    end
  end
end

module Capybara
  class Session
    prepend MonkeypatchSession
  end
end
