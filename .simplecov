unless ENV["COVERAGE"] == "false"
  SimpleCov.coverage_dir("coverage/simplecov")
  SimpleCov.start "rails" do
    add_filter "/spec/"
    add_filter "/app/controllers/admin/"
    add_filter "/app/lib/black_box/"
    add_filter "/app/views/admin/"

    enable_coverage :branch

    add_group "Decorators", "app/decorators"
    add_group "Errors", "app/errors"
    add_group "Liquid tags", "app/liquid_tags"
    add_group "Policies", "app/policies"
    add_group "Queries", "app/queries"
    add_group "Sanitizers", "app/sanitizers"
    add_group "Serializers", "app/serializers"
    add_group "Services", "app/services"
    add_group "Uploaders", "app/uploaders"
    add_group "View objects", "app/view_objects"
  end
end
