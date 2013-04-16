class DT3Div

	def self.downloadTo(src_url,src_path,dest_filepath)
		Net::HTTP.start(src_url) { |http2|
			resp2 = http2.get(src_path)
			open(dest_filepath, "w+") { |file2|
				file2.write(resp2.body)
			}
		}
		return true
	end

	def self.checkValidDir(dir)
		if dir!= '..' and dir != '.' and dir!= '.svn' and dir!= '.git'
			return true
		else
			return false
		end
	end

	def rmsymlink(symlink)
		if File.symlink?( symlink )
			FileUtils.rm_r( symlink )
		end
	end
	def self.db_image_list 
		images_arr = []
		
		Dir.glob(DT3CONST['DBIMAGES']+'/*.sql').sort.each {|sql|
			image = Hash.new
			if File.extname(sql) == '.sql'
				if(sql.split('.').count == 3) 
					image['version'] = sql.split('.')[1]
					image['name'] = File.basename(sql.split('.')[0])
				elsif(sql.split('-').count == 2) 
					image['version'] = sql.split('-')[1].split('.')[0]
					image['name'] = File.basename(sql.split('-')[0])
				else
					image['version'] = '[MASTER]'
					image['name'] = File.basename(sql,'.*')
				end
				image['time'] = File.mtime(sql).strftime("%Y-%m-%d") 
				image['filename'] = sql

				images_arr << image
			end
		}
		return images_arr
	end



end
