require 'spec_helper'

describe Typo3Helper do
	describe '.get_typo3_versions' do
		it "should return a string including 4.7.1" do
			versions = Typo3Helper.get_typo3_versions
			versions.should include("4.7.1")
			versions.should_not include("9.7.1")
		end
	end
end

describe DT3Div do
	describe '.downloadTo' do
		it "should download static_tables to tmp" do
			DT3Div.downloadTo('typo3.org','/extensions/repository/download/templavoila/1.8.0/t3x/','/tmp/templavoila.t3x').should == true
			File.exist?('/tmp/templavoila.t3x').should be_true
			ExpandT3x::expand('/tmp/templavoila.t3x','/tmp/templavoila').should be_true
			File.exist?('/tmp/templavoila/ext_emconf.php').should be_true
			FileUtils.rm_r('/tmp/templavoila')
			File.delete('/tmp/templavoila.t3x')

		end
	end

	describe '.checkValidDir' do
		it "should return false for .. . .svn and .git and else return true" do
			DT3Div.checkValidDir('..').should == false
			DT3Div.checkValidDir('.').should == false
			DT3Div.checkValidDir('.git').should == false
			DT3Div.checkValidDir('.svn').should == false
			DT3Div.checkValidDir('another dir').should == true
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



