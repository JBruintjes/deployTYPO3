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
require 'lib/dt3_div'
require 'lib/typo3_helper'


CONFIG = LoadConfig::load_config
DT3CONST = InitDT3::load_constants
describe LoadConfig do
	describe '.load_config' do
		it "should return the yaml config as array" do
			LoadConfig.load_config.should include("deploymentName")
		end
	end
end

def describe_rake_task(task_name, filename, &block)
	require "rake"

	describe "Rake task #{task_name}" do
		attr_reader :task

		before(:all) do
			@rake = Rake::Application.new
			Rake.application = @rake
			load filename
			@task = Rake::Task[task_name]
		end

		after(:all) do
			Rake.application = nil
		end

		def invoke!
			for action in task.instance_eval { @actions }
				instance_eval(&action)
			end
		end

		instance_eval(&block)
	end
end
