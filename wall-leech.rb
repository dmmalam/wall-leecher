#!/usr/bin/env ruby
# Wall-leecher Wallpaper downloader
# © 2011 Dharmesh Malam
# FreeBSD License

$LOAD_PATH << './lib'
$LOAD_PATH << './sites'

require 'skins_be'
require 'options'

require 'nokogiri'
require 'open-uri'
require 'optparse'
require 'ostruct'
require 'rbconfig'

include WallLeech

#module WallLeech

  def start
  
    #Initialize sites
    sites = Skins_be.site_params
    #Parse options
    options = Options.new(sites).parse_options(ARGV)
  
    #Download images
    Skins_be.new(options).fetch_pages
  end

#end

start











