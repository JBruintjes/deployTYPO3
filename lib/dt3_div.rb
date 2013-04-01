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
end
