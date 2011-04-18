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
    { "skins.be" => { :first => {default:1,
                              cmd:'-f N',
                              long_cmd:'--first N',
                              desc:'First page to download from',
                              type:'decimal',
                              validate: ->p{ p && p.is_a?(Fixnum) && p > 0 },
                              error:'Must be a positive number'},
                     :last => {default:10,
                              cmd:'-l N',
                              long_cmd:'--last N',
                              type:'decimal',
                              desc:'Last page to download to',
                              validate: ->p{ p && p.is_a?(Fixnum) && p > 0 },
                              error:'Must be a positive number'},
                     :all => {default:false,
                             cmd:'-a',
                             long_cmd:'--all',
                             desc:'Download all. Overides --last.'}
                           }}
                         
  end

  def self.to_s
    "Skins.be leecher"
  end
  
  def fetch_pages
    page_url = SKINS_TAG_URL + @options.resolution + '/page'
  
    first = @options.params.first
    last = @options.params.last
  
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