# frozen_string_literal: true

require 'covered/policy'

def initialize(...)
	super
	
	require 'set'
	require 'rugged'
	@repository = nil
	@repository_path = context.root
end

# bake load_coverage_from_simplecov git:coverage
# @parameter branch [String] the branch to compare against.
# @parameter repository_path [String] the path of the repository to diff.
# @parameter input [Covered::Policy] the input policy to use.
def statistics(branch: self.default_branch, repository_path: nil, input:)
	@repository_path = repository_path
	input ||= context.lookup("covered:policy:current").call
	modifications = lines_modified(branch)
	
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

private

def repository
	@repository ||= Rugged::Repository.discover(@repository_path)
end

def default_branch
	"main"
end

# Compute the lines modified for a given branch, returning a hash of paths to a set of line numbers.
# @returns [Hash(String, Set(Integer))]
def lines_modified(branch)
	result = Hash.new{|k,v| k[v] = Set.new}
	
	diff = repository.diff(repository.rev_parse(branch), repository.last_commit)
	
	diff.each_patch do |patch|
		path = patch.delta.new_file[:path]
		
		patch.each_hunk do |hunk|
			hunk.each_line do |line|
				result[path] << line.new_lineno if line.addition?
			end
		end
	end

	result.default = nil
	return result.freeze
end
