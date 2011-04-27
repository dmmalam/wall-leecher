# Wall-leecher Wallpaper downloader
# © 2011 Dharmesh Malam
# ISC License

require 'nokogiri'
require 'open-uri'
require 'ostruct'
require 'leecher'

module WallLeecher
  module Sites

    # Scrape simpledesktop.com and queue wallpapers for EM
    # Scrapes http://simpledesktops.com/browse[start - last]
    class Wallbase < Leecher
      WALLBASE_URL = 'http://wallbase.cc/wallpaper'
      PIC_XPATH = '//img[starts-with(@src,"http://wallbase2.org")]'
      NEXT_PAGE_XPATH = '//p[starts-with(@class,"prev")]/a'
      RESOLUTION_XPATH = '//div[@class="fancy left"]/span[@class = "white"]'
      
      # Return site params for options parser
      def self.site_params
        { :first =>       {default:10_000,
                           cmd:'-f',
                           long_cmd:'--first [N]',
                           desc:'First page to download from.',
                           type:Integer,
                           validate: ->p{ p && p.is_a?(Fixnum) && p > 0 },
                           error:'Must be a positive number!'},
          :number =>      {default:100,
                           cmd:'-n N',
                           long_cmd:'--number N',
                           desc:'How many wallpapers to download.',
                           type:Integer,
                           validate: ->p{ p && p.is_a?(Fixnum) && p > 0 },
                           error:'Must be a positive number!'},
          :all =>         {default:false,
                           cmd:'-a',
                           long_cmd:'--[no-]all',
                           desc:'Download all. Overrides --number.'},
          :min_res =>     {default:'1920x1200',
                           cmd:'-m',
                           long_cmd:'--min_res',
                           desc:'Only download above this resolution. Default: #{Options.default_resolution}.',
                           type:String,
                           validate: ->p{ p &&  p =~ /\d+x\d/},
                           error:'Invalid resolution! Please use WxH format!'}
        }
      end

      def self.to_s
        "Wallbase leecher"
      end
  
      # Initialise the leecher
      def fetch
        first = @options.params.first
        number = @options.params.number unless @options.params.all
        reactor {scrape_links(WALLBASE_URL, first, number, 1)} #Start the reactor
      end
  
      # Scrape each page while doing all IO async
      # Returns a function to call later
      def scrape_links(url, pic, number, acc)
      
        img_url = url + '/' + pic.to_s
      
        # Get page async
        fetcher = Fetcher.new(img_url).get
      
        fetcher.callback do |response|
          # Decode
          doc = Nokogiri::HTML response
       
          pic_node = doc.xpath(PIC_XPATH)
          if pic_node.empty?
            @log.warn("No download file for #{url}")
          else
            # Only dl if resolutions is above min
            res = doc.xpath(RESOLUTION_XPATH).first.child.text.split('x')
            min_res = @options.params.min_res.split('x')
            
            if (res[0] >= min_res[0] && res[1] >= min_res[1])
                link = pic_node.first['src']
                Fetcher.new(link).save(prep_file(link, @options.output))  # Queue download
            else
              @log.warn("Skipping as resolution (#{res.join('x')}) too low.")
            end
          
          end

          if (@options.params.all || acc < number )
            scrape_links url, pic + 1, number, acc + 1
          else
            shutdown
          end
        end
      
        fetcher.errback do
          @log.error "Could not download number #{pic}. Re-trying..."
          scrape_links url, pic, number, acc
          #shutdown 
        end
      end
  
    protected
  
      def prep_file(url, dir)
        parts = url.split('/')
        File.join(dir, parts[-3] + '-' + parts[-1])
      
      end
  
    end # Class Skins_be
  end # Module Sites
end # Module WallLeecher