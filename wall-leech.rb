#!/usr/bin/env ruby
# Wall-leecher Wallpaper downloader
# © 2011 Dharmesh Malam
# FreeBSD License

$LOAD_PATH << './lib' << './sites'
# Internal
require 'skins_be'
require 'simple_desktop'
require 'national_geographic'
require 'wallbase'
require 'options'
# External
require 'logger'

module WallLeech

  # Start WallLeech
  def start
        
    # Initialize sites
    sites = Module.constants.inject({}) do |s, k|
              klass = Object.const_get k
              s[k] = klass.site_params  if k != k.upcase && Leecher > klass
              s
            end
 
    # Parse options
    options = Options.new(sites).parse_options(ARGV)
    
    # Setup logger
    log = Logger.new(STDOUT)
    log.level = options.debug ? Logger::DEBUG : options.verbose ? Logger::INFO : Logger::WARN
    
    log.debug(options)
    
    # Leech
    leecher = Object.const_get options.site
    leecher.new(options, log).fetch
  end

end

include WallLeech
#Lets get this party started
start
