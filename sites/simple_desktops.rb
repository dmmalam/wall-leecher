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
  class SimpleDesktops < Leecher
    SIMPLE_DESKTOP_URL = 'http://simpledesktops.com'
    BROWSE_URL = '/browse'
    PIC_REGEX = /^http:\/\/static.simpledesktops.com\/desktops.*png$/
    OLDER_URL_XPATH = '//a[@class="older"]'
    
    # Return site params for options parser
    def self.site_params
     { :first =>  {default:1,
                   cmd:'-f',
                   long_cmd:'--first [N]',
                   desc:'First page to download from.',
                   type:Integer,
                   validate:->p{ p && p.is_a?(Fixnum) && p > 0 },
                   error:'Must be a positive number!'},
      :last =>    {default:10,
                   cmd:'-l',
                   long_cmd:'--last [N]',
                   type:Integer,
                   desc:'Last page to download to',
                   validate:->p{ p && p.is_a?(Fixnum) && p > 0 },
                   error:'Must be a positive number!'},
      :all =>     {default:false,
                   cmd:'-a',
                   long_cmd:'--[no-]all',
                   desc:'Download all. Overides --last.'}
      }
    end

    def self.to_s
      "Simple Desktop leecher"
    end
  
    # Initialise the leecher
    def fetch
      @page_url = SIMPLE_DESKTOP_URL + BROWSE_URL
  
      first = @options.params.first.to_i
      last = @options.params.last.to_i unless @options.params.all
      last = first if @last && @last < first
            
      reactor {scrape_links(first, last)} #Start the reactor
    end
  
    # Scrape each page while doing all IO async
    # Returns a function to call later
    def scrape_links(page, last)
        if   !@last ||  page <= @last
          @log.info "Page: #{page}"
          url = @page_url + '/' + page.to_s
          
          # Get page async
          fetcher = Fetcher.new(url).get
          
          fetcher.callback do |response|
            # Decode
            doc = Nokogiri::HTML response
            as = doc.search('a') 
           
            # Filter links
            links = as.find_all do |a| 
             a['href'] =~ PIC_REGEX
            end
          
            links.each do |l|
              link =  l['href']
              Fetcher.new(link).save(prep_file(link, @options.output))  # Queue download
            end
          
            next_page = doc.xpath(OLDER_URL_XPATH)
            if next_page.empty? 
              shutdown
            else
              scrape_links page + 1, last 
            end
          end
          
          fetcher.errback do
            shutdown 
          end
          
    
        else
          shutdown
        end
    end
  
  end # Class Skins_be
  
end # Module WallLeecher