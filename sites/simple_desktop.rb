#!/usr/bin/env ruby
# Wall-leecher Wallpaper downloader
# © 2011 Dharmesh Malam
# FreeBSD License

require 'nokogiri'
require 'open-uri'
require 'ostruct'
require 'leecher'

module WallLeech

  # Scrape simpledesktop.com and queue wallpapers for EM
  # Scrapes http://simpledesktops.com/browse[start - last]
  class SimpleDesktop < Leecher
    SIMPLE_DESKTOP_URL = 'http://simpledesktops.com'
    BROWSE_URL = '/browse'
    PIC_REGEX = /^http:\/\/static.simpledesktops.com\/desktops.*png$/
    OLDER_URL_XPATH = '//a[@class="older"]'
    
    # Return site params for options parser
    def self.site_params
      { "skins.be" => { :first =>       {default:1,
                                         cmd:'-f N',
                                         long_cmd:'--first N',
                                         desc:'First page to download from.',
                                         type:'Fixnum',
                                         validate: ->p{ p && p.is_a?(Fixnum) && p > 0 },
                                         error:'Must be a positive number'},
                        :last =>       {default:10,
                                         cmd:'-l N',
                                         long_cmd:'--last N',
                                         type:'Fixnum',
                                         desc:'Last page to download to',
                                         validate: ->p{ p && p.is_a?(Fixnum) && p > 0 },
                                         error:'Must be a positive number'},
                        :all =>         {default:false,
                                         cmd:'-a',
                                         long_cmd:'--[no-]all',
                                         desc:'Download all. Overides --last.'},
                           }}
                         
    end

    def self.to_s
      "Simple Desktop leecher"
    end
  
    # Initialise the leecher
    def fetch
      @page_url = SIMPLE_DESKTOP_URL + BROWSE_URL
  
      first = @options.params.first.to_i
      @last = @options.params.last.to_i unless @options.params.all
      
      @q << scrape_links(first) # Queue up first page
            
      reactor #Start the reactor
    end
  
    # Scrape each page while doing all IO async
    # Returns a function to call later
    def scrape_links(page)
      lambda do
        
        if  !@last ||  page <= @last
          url = @page_url + '/' + page.to_s
          # Get page async  
          @q << get_url(url) do |response|
                              if response.empty?
                                  @log.error "#{url} is empty"
                                  @q << shutdown
                              else
                                # Decode
                                doc = Nokogiri::HTML response
                                as = doc.search('a') 
                                # Filter links
                                links = as.find_all do |a| 
                                  a['href'] =~ PIC_REGEX
                                end
           
                                links.each do |l|
                                  link =  l['href']
                                  @q <<  save_file(link, prep_file(link, @options.output))  # Queue download
                                end
                              
                                next_page = doc.xpath(OLDER_URL_XPATH)
                                @q << (next_page.empty? ? shutdown : scrape_links(page + 1)) # Recurse with next page
                              end
                            end          
        else
          @q << shutdown
        end
      end
    end
  
  end # Class Skins_be
  
end # Module WallLeecher