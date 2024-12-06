describe KnapsackPro::Config::CI::Base do
  its(:node_total) { should be nil }
  its(:node_index) { should be nil }
  its(:node_build_id) { should be nil }
  its(:node_retry_count) { should be nil }
  its(:commit_hash) { should be nil }
  its(:branch) { should be nil }
  its(:project_dir) { should be nil }
  its(:user_seat) { should be nil }
end
