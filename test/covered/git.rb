# frozen_string_literal: true

require 'covered/git/version'

describe Covered::Git do
	it "has a version number" do
		expect(Covered::Git::VERSION).to be =~ /\d+\.\d+\.\d+/
	end
end
