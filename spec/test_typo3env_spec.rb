require 'spec_helper'

describe Typo3Helper do

	describe '.compile_and_import_joined_sql' do
		it "should create, compile and import the existing joined sql file" do

			extList = Typo3Helper.get_ext_list_from_config_and_extdirs
			extList.should include('cms')
			
			Typo3Helper.pre_compile_joined_sql(extList).should == true
			
			Typo3Helper.compile_and_import_joined_sql.should include("compileSQL")
			
			File.exist?(DT3CONST['JOINEDSQL']).should be_true
			s = File.open(DT3CONST['JOINEDSQL'], 'r') { |f| f.read } 
			s.should include("CREATE TABLE pages")

			DT3MySQL::show_tables.should include("pages")

			File.delete(DT3CONST['JOINEDSQL'])

			DT3MySQL::flush_tables == true
			DT3MySQL::show_tables.should_not include("pages")

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

	describe '.setLocalconfDbSettings' do
		it "should set or replace db settings" do
			Typo3Helper::setLocalconfDbSettings('dbname','user','password','host').should == true
		end
	end

end
