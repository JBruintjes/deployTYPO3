class ExpandT3x

	def self.expand(t3xfile, extdir)

		if (!File.exist? 'web/dummy/typo3temp/extensions.xml')
			Typo3Helper::download_ext_xml
		end

		puts "reading in enrollment file; this could take a while."  
		data = Nokogiri::XML::Reader(File.open("web/dummy/typo3temp/extensions.xml"))  

		result = []
		data.each do |node|  
			if(node.name == "extension" && node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT)  
				
				doc = Nokogiri::XML(node.outer_xml)  

				doc.xpath('//*[@extensionkey="dam"]/version[@version="1.2.2"]').each do|n|
					hash = {}
					n.children.each do |c|
						hash[c.node_name] = c.content
					end
					result << hash
				end
			end  
		end  

		depenc   = Base64.encode64(result[0]['dependencies']).gsub(/\n/, '') 
		cmd = "/usr/bin/php -c lib/expandt3x/php.ini lib/expandt3x/expandt3x.php #{t3xfile}  #{extdir} #{depenc}"
		system(cmd)
	end
end
