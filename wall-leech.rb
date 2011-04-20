#!/usr/bin/env ruby
# Wall-leecher Wallpaper downloader
# © 2011 Dharmesh Malam
# FreeBSD License

$LOAD_PATH << './lib' << './sites'
# Internal
require 'skins_be'
require 'options'
# External
require 'logger'

module WallLeech

  # Start WallLeech
  def start
  
    # Initialize sites
    sites = Skins_be.site_params
    
    # Parse options
    options = Options.new(sites).parse_options(ARGV)
    
    # Setup logger
    log = Logger.new(STDOUT)
    log.level = options.verbose ? Logger::DEBUG : Logger::INFO
    
    log.debug(options)
    
    # Leech
    Skins_be.new(options, log).fetch
    
  end

end

#Lets get this party started
WallLeech::start
