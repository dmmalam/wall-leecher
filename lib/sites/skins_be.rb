# Wall-leecher Wallpaper downloader
# © 2011 Dharmesh Malam
# ISC License

require 'nokogiri'
require 'open-uri'
require 'ostruct'
require 'leecher'

module WallLeecher 
  module Sites

    # Scrape skins.be and queue wallpapers for EM
    # Scrapes www.skins.be/tags/[Resolution]/page/[start - last]
    class SkinsBe < Leecher
      SKINS_TAG_URL = 'http://www.skins.be/tags/'
      SKINS_WALLPAPERS_URL = "wallpapers.skins.be"
      SKINS_WALLPAPER_URL = "wallpaper.skins.be"
      SKINS_LAST_PAGE_XPATH = '//*[@alt="the last"]'
      SKINS_PAGE_PATH = '/page'
 
      # Return site params for options parser
      def self.site_params
        { :first =>       {default:1,
                           cmd:'-f',
                           long_cmd:'--first [N]',
                           desc:'First page to download from.',
                           type:Integer,
                           validate: ->p{ p && p.is_a?(Fixnum) && p > 0 },
                           error:'Must be a positive number!'},
          :last =>        {default:10,
                           cmd:'-l',
                           long_cmd:'--last [N]',
                           type:Integer,
                           desc:'Last page to download to',
                           validate: ->p{ p && p.is_a?(Fixnum) && p > 0 },
                           error:'Must be a positive number!'},
          :all =>         {default:false,
                           cmd:'-a',
                           long_cmd:'--[no-]all',
                           desc:'Download all. Overides --last.'},
          :sort =>        {default:false,
                           cmd:'-s',
                           long_cmd:'--[no-]sort',
                           desc:'Organize files into directories according to name.'},
          :pretty =>      {default:true,
                           cmd:'-p',
                           long_cmd:'--[no-]pretty',
                           desc:'Prettyify the directory name. In conjunction with --directories'},
          :resolution =>  {default:Options.default_resolution,
                           cmd:'-r',
                           long_cmd:'--resolution [WxH]',
                           desc:"Resolution of wallpapers to download. Default: #{Options.default_resolution}",
                           type:String,
                           validate: ->p{ p &&  p =~ /\A\d+x\d/}, # FIXME:/\A\d+x\d\z/ doesnt work?
                           error:'Invalid resolution! Please use WxH format!'}
          }                         
      end

      def self.to_s
        "Skins.be leecher"
      end
  
      # Initialise the leecher
      def fetch
        @page_url = SKINS_TAG_URL + @options.params.resolution + SKINS_PAGE_PATH
  
        last_page = get_last_page(@options.params.resolution)
        first = [@options.params.first.to_i, last_page].min
        last =   [first, 
                   (@options.params.all ? last_page : [@options.params.last.to_i, last_page].min)].max
      
        reactor {scrape_links(first, last)} #Start the reactor
      end
  
      # Scrape each page while doing all IO async
      # Returns a function to call later
      def scrape_links(page, last)
        #Loop while pages exist
        if page <= last
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
               a['href'] =~ /#{SKINS_WALLPAPER_URL}.*#{@options.params.resolution}.*/
              end
          
              links.each do |l|
                link = adjust_link l['href'] # Create direct URL to jpg
                Fetcher.new(link).save(prep_file(link, @options.output))  # Queue download
              end
              scrape_links(page += 1, last)
            end
            fetcher.errback do
              shutdown 
            end
        else
          shutdown    
        end 
      end
  
      protected
  
        # Pure function to change directory name
        # from: '<first>-<last>'
        # to:   '<First> <Last>
        def beutify_name(name)
          @options.params.pretty ?
                          name.gsub(/-/, ' ').gsub(/([a-z]+)/) {|s| s.capitalize} :
                          name
        end
      
        # Pure function to create correct filename
        def prep_file(url, dir)
          parts = url.split('/')
          directory = @options.params.sort ? File.join(dir, beutify_name(parts[3])) : dir 
          super(url, directory)
        end

        # Pure function to adjust links to point at jpgs directly
        # from: 'http://wallpaper.skins.be/<name>/<id>/<resolution>/'
        # to:   'http://wallpapers.skins.be/<name>/<name>-<resolution>-<id>.jpg
        def adjust_link(link)
          parts = link.split('/')
          pic = parts[3] + '-' + parts[5] + '-' + parts[4] +'.jpg'
          parts[2] = SKINS_WALLPAPERS_URL

          (parts[0..3] << pic).join('/')
        end
      
        # Blocking IO
        # Used only in Initialize
        # Works out the last page of images
        def get_last_page(resolution)
          url = SKINS_TAG_URL + resolution
          doc = Nokogiri::HTML(open(url))
  
          last_url = doc.xpath( SKINS_LAST_PAGE_XPATH ).first.parent['href']
          last = last_url.scan(/\d+/).last.to_i
          @log.debug("Computed last page is: #{last}")
          last
        end
    
    end # Class Skins_be
  
  end # Module Sites
end # Module WallLeecher