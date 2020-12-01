require 'diff-lcs'

Around "@skip-when-diff-lcs-1.4" do |scenario, block|
  if Diff::LCS::VERSION.to_f >= 1.4
    warn "Skipping scenario #{scenario.title} on `diff-lcs` v#{Diff::LCS::VERSION.to_f}"
  else
    block.call
  end
end

Around "@skip-when-diff-lcs-1.3" do |scenario, block|
  if Diff::LCS::VERSION.to_f < 1.4
    warn "Skipping scenario #{scenario.title} on `diff-lcs` v#{Diff::LCS::VERSION.to_f}"
  else
    block.call
  end
end
