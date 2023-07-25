# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'covered/git/changes'
require 'tmpdir'

describe Covered::Git::Changes do
	let(:root) {Dir.mktmpdir}
	let(:repository) {Rugged::Repository.init_at(root)}
	let(:changes) {subject.new(root)}
	
	def before
		super
		
		repository.config['user.name'] = "Test Author"
		repository.config['user.email'] = "test@example.com"
		
		oid = repository.write("Hello World!\n" * 10, :blob)
		
		index = repository.index
		index.add(:path => "readme.md", :oid => oid, :mode => 0100644)
		
		options = {
			author: {email: "test@example.com", name: "Test Author", time: Time.now},
		}
		options[:tree] = index.write_tree(repository)
		options[:message] ||= "Initial commit."
		options[:parents] = []
		options[:update_ref] = 'HEAD'
		
		Rugged::Commit.create(repository, options)
	end
	
	it "has a default branch" do
		expect(changes.default_branch).to be == "main"
	end
	
	with "branch" do
		def before
			super
			
			@branch = repository.branches.create("my-branch", "HEAD")
			
			lines = ["Hello World!\n"] * 10
			lines[0] = ["Goodbye World!\n"]
			lines << "Hullo World!\n"
			oid = repository.write(lines.join, :blob)
			
			index = repository.index
			index.read_tree(repository.head.target.tree)
			index.add(:path => "readme.md", :oid => oid, :mode => 0100644)
			
			options = {
				author: {email: "test@example.com", name: "Test Author", time: Time.now},
			}
			options[:tree] = index.write_tree(repository)
			options[:message] ||= "Initial commit."
			options[:parents] = repository.empty? ? [] : [repository.head.target].compact
			options[:update_ref] = 'HEAD'
			
			Rugged::Commit.create(repository, options)
		end
		
		it "can detected modified lines" do
			lines_modified = changes.lines_modified("my-branch")
			
			expect(lines_modified).to be(:include?, "readme.md")
			
			readme_lines = lines_modified["readme.md"]
			expect(readme_lines).to be(:include?, 1)
			expect(readme_lines).to be(:include?, 11)
		end
	end
end
