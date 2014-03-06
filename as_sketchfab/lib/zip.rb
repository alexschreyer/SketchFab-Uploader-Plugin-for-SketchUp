module Zip

	USING_WINDOWS = (RUBY_PLATFORM =~/mswin/)
	if USING_WINDOWS
		SevenZip = File.join(File.dirname(__FILE__), '..', 'bin', '7za.exe')
	end

	def self.create(zip_name, *files)
		if USING_WINDOWS
			system "#{SevenZip} a #{zip_name} #{files.join(' ')}"
		else
			system "zip -r #{zip_name} #{files.join(' ')}"
		end
	end
end
