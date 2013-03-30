require 'rake'
require 'fileutils'  
require "yaml"
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'net/http'
require 'lib/typo3_helper'

require 'spec_helper'

describe Typo3Helper do
	describe '.get_typo3_versions' do

		it "should return a string including 4.7.1" do
			Typo3Helper.get_typo3_versions.should include("4.7.1")
		end

		it "should return a string not including 9.7.1" do
			Typo3Helper.get_typo3_versions.should_not include("9.7.1")
		end

	end
end


#rake conf_init sitename=t3deptest t3version=4.7.9 dbname=pimsql1 dbuser=pimsql1 dbpass=test dbhost=localhost

describe_rake_task "help", "Rakefile" do

	#it "should build my other thing first" do
	# 	task.prerequisites.should include("help")
	#end

	#it "should do something" do
	#	@built_my_thing = false
	#	Builder.should_receive(:build).with(:my_thing)
	#invoke!
	#	@built_my_thing.should be(false)
	#end
end



