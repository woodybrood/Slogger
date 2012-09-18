=begin
Plugin: GenericIFTTT / IFTTT logger
Description: Parses GenericIFTTT posts logged by IFTTT.com
Author: [Dan Woodward](https://github.com/woodybrood)
Configuration:
  generic_ifttt_input_file: "/path/to/dropbox/ifttt/facebook.txt"
Notes:
  - Configure IFTTT to log GenericIFTTT status posts to a text file.
  - You can use the recipe at https://ifttt.com/recipes/56242
  - and personalize if for your Dropbox set up.
  - 
  - Unless you change it, the recipe will write to the following
  - location:
  - 
  - {Dropbox path}/AppData/ifttt/facebook/facebook.md.txt
  -
  - You probably don't want that, so change it in the recipe accordingly.
  -
  - On a standard Dropbox install on OS X, the Dropbox path is
  -
  - /Users/username/Dropbox
  -
  - so the full path is:
  - 
  - /Users/username/Dropbox/AppData/ifttt/facebook/facebook.md.txt
  -
  - You should set generic_ifttt_input_file to this value, substituting username appropriately.
=end

config = { 
  'description' => ['Parses GenericIFTTT posts logged by IFTTT.com',
                    'generic_ifttt_input_file is a string pointing to the location of the file created by IFTTT.',
                    'The recipe at https://ifttt.com/recipes/56242 determines that location.'],
  'generic_ifttt_input_file' => '', 
  'generic_ifttt_star' => false,
  'generic_ifttt_tags' => '@social @blogging'
}

$slog.register_plugin({ 'class' => 'GenericIFTTTLogger', 'config' => config })

class GenericIFTTTLogger < Slogger
	require 'date'
	require 'time'

	def do_log
	    if @config.key?(self.class.name)
    	  config = @config[self.class.name]
      		if !config.key?('generic_ifttt_input_file') || config['generic_ifttt_input_file'] == []
        		@log.warn("GenericIFTTTLogger has not been configured or an option is invalid, please edit your slogger_config file.")
        		return
      		end
    	else
      		@log.warn("GenericIFTTTLogger has not been configured or a feed is invalid, please edit your slogger_config file.")
      	return
    end

    tags = config['generic_ifttt_tags'] || ''
    tags = "\n\n#{@tags}\n" unless @tags == ''

    inputFile = config['generic_ifttt_input_file']

    @log.info("Logging GenericIFTTTLogger posts at #{inputFile}")

    regPost = /^Post: /
    regDate = /^Date: /
    ampm    = /(AM|PM)\Z/
    pm      = /PM\Z/

    last_run = @timespan
    
    ready = false
    options = {}
    options['starred'] = config['generic_ifttt_star']
    options['uuid'] = %x{uuidgen}.gsub(/-/,'').strip

    f = File.new(inputFile)
    content = f.read
    f.close

    content.each do |line|
			 if line =~ regPost
			   	line = line.gsub(regPost, "")
				  options['content'] = "#### GenericIFTTT\n\n#{line}\n\n#{tags}"
          ready = false
			 elsif line =~ regDate
			 	  line = line.strip
				  line = line.gsub(regDate, "")
				  line = line.gsub(" at ", ' ')
				  line = line.gsub(',', '')
			
				  month, day, year, time = line.split
				  hour,min = time.split(/:/)
				  min = min.gsub(ampm, '')

				  if line =~ pm
				  	x = hour.to_i
				  	x += 12
				  	hour = x.to_s
				  end

				  month = Date::MONTHNAMES.index(month)
				  ltime = Time.local(year, month, day, hour, min, 0, 0)
				  date = ltime.to_i

				  next unless date > last_run.to_i

				  options['datestamp'] = ltime.utc.iso8601
          ready = true
			 end
		  end    	

      if ready
        sl = DayOne.new
        sl.to_dayone(options)
        ready = false
      end
	   end
  end
end