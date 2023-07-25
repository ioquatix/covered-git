# frozen_string_literal: true

require 'covered/policy'
require 'covered/git/branch_changes'

def initialize(...)
	super
	
	require 'set'
	require 'rugged'
end

# bake load_coverage_from_simplecov git:coverage
# @parameter root [String] the root directory of the git repository.
# @parameter branch [String] the branch to compare against.
# @parameter input [Covered::Policy] the input policy to use.
def statistics(root: context.root, branch: nil, input:)
	input ||= context.lookup("covered:policy:current").call
	changes = Covered::Git::BranchChanges.new(root)
	modifications = changes.lines_modified(branch)
	
	# Calculate statistics:
	statistics = Covered::Statistics.new
	
	input.each do |coverage|
		if modified_lines = modifications[coverage.source.path]
			scoped_coverage = coverage.for_lines(modified_lines)
			statistics << scoped_coverage
		end
	end
	
	return statistics
end