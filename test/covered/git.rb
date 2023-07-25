# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'covered/git/version'

describe Covered::Git do
	it "has a version number" do
		expect(Covered::Git::VERSION).to be =~ /\d+\.\d+\.\d+/
	end
end
