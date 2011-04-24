# Wall-leecher Wallpaper downloader
# © 2011 Dharmesh Malam
# ISC License
path = File.expand_path(File.join(File.dirname(__FILE__), 'sites'))
$LOAD_PATH.unshift path unless $LOAD_PATH.include? path

# Internal
require 'skins_be'
require 'simple_desktops'
require 'national_geographic'
require 'wallbase'
require 'options'
# External
require 'logger'

module WallLeecher

  # Start WallLeecher
  def start
        
    # Initialize sites
    sites = WallLeecher::Sites.constants.inject({}) do |s, k|
              klass = WallLeecher::Sites.const_get k
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
    leecher = WallLeecher::Sites.const_get options.site
    leecher.new(options, log).fetch
  end

end

include WallLeecher
#Lets get this party started
start
