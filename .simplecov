if ENV["COVERAGE"]
  SimpleCov.start "rails" do
    add_filter "/spec/"
    add_filter "/dashboards/"
    add_filter "/app/controllers/admin/"
    add_filter "/app/controllers/internal/"
    add_filter "/app/black_box/"
    add_filter "/app/fields/"
    add_filter "/app/views/admin/"
  end
end
