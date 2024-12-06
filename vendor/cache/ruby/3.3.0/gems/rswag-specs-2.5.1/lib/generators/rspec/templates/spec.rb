require 'swagger_helper'

RSpec.describe '<%= controller_path %>', type: :request do
<%  @routes.each do | template, path_item | %>
  path '<%= template %>' do
<%    unless path_item[:params].empty? -%>
    # You'll want to customize the parameter types...
<%      path_item[:params].each do |param| -%>
    parameter name: '<%= param %>', in: :path, type: :string, description: '<%= param %>'
<%      end -%>
<%    end -%>
<%    path_item[:actions].each do | action, details | %>
    <%= action %>('<%= details[:summary] %>') do
      response(200, 'successful') do
<%      unless path_item[:params].empty? -%>
<%        path_item[:params].each do |param| -%>
        let(:<%= param %>) { '123' }
<%        end -%>
<%      end -%>

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
<%    end -%>
  end
<%  end -%>
end
