require 'spec_helper'

describe Rake do
	describe 'rake  sub:rmdirStruct' do
		it "should rm all typo3 dirs" do
			FileUtils.rm_r 'web', :force => true  
			FileUtils.mkdir 'web' 
			cmd = "rake sub:rmdirStruct"
			system(cmd)
			File.directory?('web').should be_false
		end
	end
	describe 'rake sub:dirStruct' do
		it "should create typo3 dirs" do
			cmd = "rake sub:dirStruct"
			system(cmd)
			File.directory?('web').should be_true
		end
	end

	describe 'rake init:conf' do
		it "should create conf file" do
			cmd = "rake sub:rmdirStruct"
			system(cmd)
			cmd = "rake sub:dirStruct"
			system(cmd)

			cmd = "rake init:conf t3version=4.7.10 dbname=testsql1 dbuser=testsql1 dbpass=test dbhost=localhost"
			system(cmd)
			File.exist?('config/config.yml').should be_true
		end
	end

	describe 'rake sub:getTarballs' do
		it "should download 4.7.10 source and dummy tarballs" do
			cmd = "rake sub:getTarballs"
			system(cmd)
			File.exist?('typo3source/typo3_src-4.7.10.tar.gz').should be_true
			File.exist?('typo3source/dummy-4.7.10.tar.gz').should be_true
		end
	end

	describe 'rake sub:unpackt3' do
		it "should unpack the source and dummy tarballs" do
			cmd = "rake sub:unpackt3"
			system(cmd)
			File.directory?('web/dummy').should be_true
			File.directory?('web/typo3_src-4.7.10').should be_true
		end
	end

end
