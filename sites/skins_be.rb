#!/usr/bin/env ruby
# Wall-leecher Wallpaper downloader
# © 2011 Dharmesh Malam
# FreeBSD License

require 'nokogiri'
require 'open-uri'
require 'ostruct'

module WallLeech


class Skins_be
  SKINS_TAG_URL = 'http://www.skins.be/tags/'
  
  attr_accessor :options
  
  def initialize(options)
    @options = options
  end
  
  def self.site_params
    { "skins.be" => { :first =>       {default:1,
                                      cmd:'-f N',
                                      long_cmd:'--first N',
                                      desc:'First page to download from.',
                                      type:'decimal',
                                      validate: ->p{ p && p.is_a?(Fixnum) && p > 0 },
                                      error:'Must be a positive number'},
                     :last =>         {default:10,
                                      cmd:'-l N',
                                      long_cmd:'--last N',
                                      type:'decimal',
                                      desc:'Last page to download to',
                                      validate: ->p{ p && p.is_a?(Fixnum) && p > 0 },
                                      error:'Must be a positive number'},
                     :all =>          {default:false,
                                      cmd:'-a',
                                      long_cmd:'--[no-]all',
                                      desc:'Download all. Overides --last.'},
                     :directories => {default:false,
                                      cmd:'-d',
                                      long_cmd:'--[no-]directories',
                                      desc:'Organize files by directories according to name.'},
                     :pretty      => {default:true,
                                      cmd:'-p',
                                      long_cmd:'--[no-]pretty',
                                      desc:'Prettyify the directory name. In conjunction with --directories'}
                           }}
                         
  end

  def self.to_s
    "Skins.be leecher"
  end
  
  def fetch_pages
    page_url = SKINS_TAG_URL + @options.resolution + '/page'
  
    first = @options.params.first
    last = @options.params.all ? get_last_page(@options.resolution) : @options.params.last
  
    first.upto(last) do |page|
      page_doc = Nokogiri::HTML(open(page_url + '/' + page.to_s))

      as = page_doc.search('a') 
      links = as.find_all do |a| a['href'] =~ /wallpaper.skins.be.*#{@options.resolution}.*/ end

      links.each do |l|
        link = adjust_link l['href'] 
        save_file link, @options.output  
      end
    end
  end
  
  def beutify_name(name)
    @options.params.pretty ?
                    name.gsub(/-/, ' ').gsub(/([a-z]+)/) {|s| s.capitalize} :
                    name
  end
  
  def save_file(url, dir)
    parts = url.split('/')
    directory = @options.params.directories ? File.join(dir, beutify_name(parts[3])) : dir 
    filename =  File.join(directory, parts[4])
    
    if File.exists?(filename)
      puts filename +" already exists. Skipping..."
    else
      puts url
      uri = URI.parse(url)
      Net::HTTP.start( uri.host ) do |http|
       # puts filename
        resp = http.get( uri.path )
        
        Dir.mkdir(directory) unless Dir.exists? directory
        
        open( filename, 'wb' ) do |file|
          file.write(resp.body)
        end
      end
    end
  end
  
  private
  
    def get_last_page(resolution)
      url = SKINS_TAG_URL + resolution
      doc = Nokogiri::HTML(open(url))
  
      last_url = doc.xpath('//*[@alt="the last"]').first.parent['href']
      last_url.scan(/\d+/).last.to_i
    end


    def adjust_link(link)
      parts = link.split('/')
      pic = parts[3] + '-' + parts[5] + '-' + parts[4] +'.jpg'
      parts[2] = "wallpapers.skins.be"

      (parts[0..3] << pic).join('/')
    end
  
end
end