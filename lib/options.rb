#!/usr/bin/env ruby
# Wall-leecher Wallpaper downloader
# © 2011 Dharmesh Malam
# FreeBSD License

require 'nokogiri'
require 'open-uri'
require 'optparse'
require 'ostruct'
require 'rbconfig'

module WallLeech

class Options
  
  attr_accessor :sites
  
  def initialize(sites)
    @sites = sites
  end

  def parse_options(argv)
    
    options = default_options
    
    opts = OptionParser.new do |opts|
      opts.banner = "Usage: wall-leech.rb --site SITE [options] [site-options]"
    
      opts.separator ""
      opts.separator "Options:"

      opts.on('-s', '--site [SITE]',
              "The site which to download from. Choose from: #{site_names}. Default: #{site_names.first}") do |s|
        raise "Unknown site. Choose from: #{site_names}" unless !s || site_names.include?(s)
        options.site = s
      end
    
      opts.on("-r", "--resolution [WxH]",
              "Resolution of wallpapers to download. Default: #{default_resolution}") do |r|
        raise "Invalid resolution: #{r} Please use WxH format" unless !r || r =~ /\d+x\d/
        options.resolution = r
      end

      opts.on("-o", "--output [DIR]",
              "Directory to save the wallpapers. Default: #{default_output}") do |o|
        raise "Output not an directory" unless !o || File.directory?(o)
        options.output = o
      end
    
      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options.verbose = v
      end

      opts.separator ""
      opts.separator "Common options:"

      opts.on("-h", "--help", "Show this message") do
        puts opts
        exit
      end

      opts.on("--version", "Show version") do
        puts version.join(".")
        exit
      end  
    
      opts.separator ""
      opts.separator "Site options: #{site_names.first}"
    
       # opts.on("-p", "--params [SITE]", "Show Params for a particular site") do |site|
       #    raise "Unknown site. Choose from: #{site_names}" unless site_names.include?(site)
       #    print_site_options sites[site]
       #    exit
       #  end
      
      options.params = default_site_options(options.site)

      sites[options.site].each_pair do |k, v|
         
        if v[:type]
          opts.on(v[:cmd], v[:long_cmd], v[:type], v[:desc] + "\tDefault: " + v[:default].to_s) do |p|
            #raise v[:error] unless p[:validate].call(p)
            options.params[k] = p
          end 
         else
           opts.on(v[:cmd], v[:long_cmd], v[:desc] + "\tDefault: " + v[:default].to_s) do 
             options.params[k] = true
           end
         end
      end
    
      
    end.parse!(argv)
    options.params = OpenStruct.new(options.params)
    options
  end

  private
  
  def version
    [0,0,1]
  end
  
  def default_resolution
    "1920x1200"
  end
  
  def default_output
    case Config::CONFIG['host_os']
      when /darwin/i
        File.expand_path('~/Pictures/wallpaper')
      when /mswin|windows/i
        File.expand_path('~\Pictures\wallpaper')
      when /linux/i
        File.expand_path('~/wallpaper')
      else
        File.expand_path('~/wallpaper')
    end
  end

  def default_options
    options = OpenStruct.new
    options.site = @sites.keys.first
    options.output = default_output
    options.resolution = default_resolution
    options.verbose = false
    options.params = nil
    options
  end
  
  def site_names
    @sites.keys 
  end
  
  def default_site_options(site)
    params ={}
    sites[site].each_pair do |k, v|
      params[k] = v[:default]
    end
    params
  end
  
  def print_site_options(params)
    params.values.each do |p|
      puts p[:cmd] + "\t" + p[:long_cmd] + '\t'
      puts p[:desc] + "\t Default:" + p[:default].to_s + "\n"
    end
  end
end # End Options

end