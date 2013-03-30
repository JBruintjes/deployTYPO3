class Typo3Helper

	def self.get_typo3_versions
		source = "http://sourceforge.net/api/file/index/project-id/20391/mtime/desc/rss"
		content = "" # raw content of rss feed will be loaded here
		open(source) do |s| content = s.read end
		rss = RSS::Parser.parse(content, false)

		#print "RSS title: ", rss.channel.title, "\n"
		#print "RSS link: ", rss.channel.link, "\n"
		#print "RSS description: ", rss.channel.description, "\n"
		#print "RSS publication date: ", rss.channel.date, "\n"

		#puts "Item values"
		
		_version_arr= []
		rss.items.each { |item|
			if item.title[0,24] =='/TYPO3 Source and Dummy/' 
				_item = item.title[24,1000].split(/\//)
				_version_arr << _item[0]
			end
		}
		return_string = ""
		version_arr = _version_arr.uniq.sort
		version_arr.each { |v|
			return_string << "version: "+ v+ "\n"
		}
		return return_string
	end

end
