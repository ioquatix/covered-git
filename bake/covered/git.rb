# frozen_string_literal: true

def initialize(...)
	super
	
	require_relative '../../lib/covered/config'
	
	require 'set'
	require 'rugged'
	@repository = nil
end

def load_coverage
	# policy
end

# bake load_coverage_from_simplecov git:coverage
# @parameter branch [String] the branch to compare against.
# @parameter input [Covered::Policy] the input policy to use.
def coverage(branch: self.default_branch, input:)
	input ||= context.lookup("covered:policy:current").call
	modifications = lines_modified(branch)
	
	# Calculate statistics:
	statistics = Covered::Statistics.new
	per_file_statistics = {}
	
	input.each do |coverage|
		modified_lines = modifications[coverage.source.path]
		next if modified_lines.nil?
		
		coverage = coverage.for_lines(modified_lines)
		per_file_statistics[coverage.source.path] = Covered::Statistics.for(coverage)
		
		statistics << coverage
	end
	
	return input
end

private

def repository(root = context.root)
	@repository ||= Rugged::Repository.discover(root)
end

def default_branch
	"main"
end

# Compute the lines modified for a given branch, returning a hash of paths to a set of line numbers.
# @returns [Hash(String, Set(Integer))]
def lines_modified(branch)
	result = Hash.new{|k,v| k[v] = Set.new}
	
	diff = repository.diff_workdir(branch)
	
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
