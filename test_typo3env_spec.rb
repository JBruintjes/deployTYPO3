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

describe Typo3Helper do

	describe '.compile_joined_sql' do
		it "should create a joined sql file" do
			Typo3Helper.compile_joined_sql.should include("compileSQL")
		end
	end

	describe '.create_be_users' do
		it "should create be users mysql command" do
			Typo3Helper.create_be_users.should include("add_beuser")
		end
	end

	describe '.get_db_settings' do
		it "should print installed db settings" do
			Typo3Helper.get_db_settings.size.should eq(4)
		end
	end

end
