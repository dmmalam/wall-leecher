#!/usr/bin/env ruby
# Wall-leecher Wallpaper downloader
# © 2011 Dharmesh Malam
# FreeBSD License

require 'nokogiri'
require 'open-uri'
require 'optparse'
require 'ostruct'
require 'rbconfig'

SKINS_TAG_URL = 'http://www.skins.be/tags/'

def get_last_page(resolution)
  url = SKINS_TAG_URL + params[:resolution]
  doc = Nokogiri::HTML(open(url))
  
  last_url = doc.xpath('//*[@alt="the last"]').first.parent['href']
  last_url.scan(/\d+/).last.to_i
end

def fetch_pages(options)
  page_url = SKINS_TAG_URL + options.resolution + '/page'
  
  start = options.params.start
  last = options.params.last
  
  start.upto(last) do |page|
    page_doc = Nokogiri::HTML(open(page_url + '/' + page.to_s))

    as = page_doc.search('a') 
    links = as.find_all do |a| a['href'] =~ /wallpaper.skins.be.*#{options.resolution}.*/ end

    links.each do |l|
      link = adjust_link l['href'] 
      save_file link, options.output  
    end
  
  end

end

def adjust_link(link)
    parts = link.split('/')
    
    pic = parts[3] + '-' + parts[5] + '-' + parts[4] +'.jpg'
    parts[2] = "wallpapers.skins.be"

    (parts[0..3] << pic).join('/')

end

def save_file(url, dir)
  uri = URI.parse(url)
  parts = url.split('/')
  puts url
  Net::HTTP.start( uri.host ) { |http|
    resp = http.get( uri.path )
    open( dir +'/' + parts[4], 'wb' ) { |file|
      file.write(resp.body)
    }
  }
  
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
  options.site = sites.keys.first
  options.output = default_output
  options.resolution = default_resolution
  options.verbose = false
  options.params = sites.values.first
  options
end

def sites
  {"skins.be" => OpenStruct.new({:start => 1,
                                 :last => 2}) }
end

def site_names
  sites.keys 
end

def version
  [0,0,1]
end

def parse_site_options
end

def parse_options(options)

  opts = OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__} --site skins.be [options] [site-options]"
    
    opts.separator ""
    opts.separator "Options:"

    opts.on('-s', '--site [SITE]',
            "The site which to download from. Choose from: #{site_names}. Default: #{site_names.first}") do |s|
      raise "Unknown site. Choose from: #{site_names}" unless !s || site_names.include?(s)
      options.site = s
    end
    
    opts.on("-r", "--resolution [WxH]",
            "The resolution of wallpapers to download. Default:#{default_resolution}") do |r|
      raise "Invalid resolution: #{r} Please use WxH format" unless !r || r =~ /\d+x\d/
      options.resolution = r
      
    end

    opts.on("-o", "--output [DIR]",
            "The directory to save the downloaded wallpapers. Default #{default_output}") do |o|
      raise "Output not an directory" unless !o || File.directory?(o)
      options.output = o
    end
    
    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options.verbose = v
    end
    
    opts.separator ""
    opts.separator "Common options:"
    
    opts.on_tail("-p", "--params [SITE]", "Show Params for a particular site") do |site|
      raise "Unknown site. Choose from: #{site_names}" unless site_names.include?(site)
      puts sites[site]
      exit
    end
    
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end

    opts.on_tail("--version", "Show version") do
      puts version.join(".")
      exit
    end
    
  end.parse!(ARGV)
  options
end
  
def start
  options = parse_options(default_options)
  #puts options
  fetch_pages options
end
  
start











