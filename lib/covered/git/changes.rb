
require 'rugged'

module Covered
	module Git
		class Changes
			def initialize(root)
				@root = root
			end
			
			def repository
				@repository ||= Rugged::Repository.discover(@root)
			end
			
			def default_branch
				"main"
			end
			
			# Compute the lines modified for a given branch, returning a hash of paths to a set of line numbers.
			# @returns [Hash(String, Set(Integer))]
			def lines_modified(branch = nil)
				branch ||= default_branch
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
		end
	end
end
