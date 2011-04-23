# Wall-leecher Wallpaper downloader
# © 2011 Dharmesh Malam
# ISC License

require 'nokogiri'
require 'open-uri'
require 'ostruct'
require 'leecher'

module WallLeecher

  # Scrape simpledesktop.com and queue wallpapers for EM
  # Scrapes http://simpledesktops.com/browse[start - last]
  class NationalGeographic < Leecher
    NATGEO_URL = 'http://photography.nationalgeographic.com'
    BROWSE_URL = '/photography/photo-of-the-day'
    PIC_XPATH = '//div[@class="download_link"]/a'
    NEXT_PAGE_XPATH = '//p[starts-with(@class,"prev")]/a'
    
    # Return site params for options parser
    def self.site_params
      { :number =>  {default:30,
                     cmd:'-n',
                     long_cmd:'--number [N]',
                     desc:'How many wallpapers to download.',
                     type:Integer,
                     validate:->p{ p && p.is_a?(Fixnum) && p > 0 },
                     error:'Must be a positive number'},
        :all =>     {default:false,
                     cmd:'-a',
                     long_cmd:'--[no-]all',
                     desc:'Download all. Overides --number'}
      }
    end

    def self.to_s
      "National Geographic Picture of Day leecher"
    end
  
    # Initialise the leecher
    def fetch
      url = NATGEO_URL + BROWSE_URL
      reactor {scrape_links(url, 0)} #Start the reactor
    end
  
    # Scrape each page while doing all IO async
    # Returns a function to call later
    def scrape_links(url, num)
      
      @log.info "Number: #{num + 1}"
      
      # Get page async
      fetcher = Fetcher.new(url).get
      
      fetcher.callback do |response|
        # Decode
        doc = Nokogiri::HTML response
       
        pic_node = doc.xpath(PIC_XPATH)
        if pic_node.empty?
          @log.warn("No download file for #{url}")
        else
          pic = pic_node.first['href']
          Fetcher.new(pic).save(prep_file(pic, @options.output))  # Queue download
        end
        
        next_page_node = doc.xpath(NEXT_PAGE_XPATH)
        next_page_url = next_page_node.first['href']
        if (next_page_node.empty? || 
            !@options.params.all && num > @options.params.number) ||
            next_page_url.empty? 
          shutdown
        else
          scrape_links NATGEO_URL + next_page_url, num + 1
        end
      end
      
      fetcher.errback do
        shutdown 
      end
    end
  
  end # Class Skins_be
end # Module WallLeecher