require 'spec_helper'
=begin
require 'rake'
require 'fileutils'  
require "yaml"
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'net/http'

require 'lib/load_config'
require 'lib/init_dt3'
require 'lib/dt3_logger'
require 'lib/typo3_helper'

require 'spec_helper'

CONFIG = LoadConfig::load_config
DT3CONST = InitDT3::load_constants
describe LoadConfig do
	describe '.load_config' do
		it "should return the yaml config as array" do
			LoadConfig.load_config.should include("deploymentName")
		end
	end
end
=end

describe Typo3Helper do
	describe '.get_typo3_versions' do

		it "should return a string including 4.7.1" do
			Typo3Helper.get_typo3_versions.should include("4.7.1")
		end

		#it "should return a string not including 9.7.1" do
		#	Typo3Helper.get_typo3_versions.should_not include("9.7.1")
		#end

	end
end

describe DT3Div do
	describe '.downloadTo' do
		it "should download static_tables to tmp" do
			DT3Div.downloadTo('typo3.org','/extensions/repository/download/static_info_tables/2.3.1/t3x/','/tmp/static_info_tables.t3x').should == true
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



