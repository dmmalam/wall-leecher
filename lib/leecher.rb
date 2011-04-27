# Wall-leecher Wallpaper downloader
# © 2011 Dharmesh Malam
# ISC License

require 'ostruct'
require 'eventmachine'
require 'em-http'
require "em-files"
require 'logger'

module WallLeecher
  class Leecher

    attr_accessor :options

    def initialize(options, log)
      @options = options
      @log = log
      Fetcher::set_log(log)
    end
    
    def reactor
      EM.kqueue # OSX, *BSD
      EM.epoll  # Linux
      EM.run do
        Signal.trap("TERM") do shutdown end
        @log.info("Starting...")
        yield
      end
    end # reactor
  
    def shutdown
       Fetcher::shutdown
    end  
        
    protected
      # Pure function to create correct filename
      def prep_file(url, dir)
        parts = url.split('/')
        File.join(dir, parts[-1])
      end
      
  end # Class Leecher

  class Fetcher
    include EM::Deferrable
      MAX_IO = 8  # Max number of concurrent network IOs
      @@ios = 0   # Count network IO requests
      MAX_WRITES = 20  # Max number of concurrent local disk IOs
      @@writes = 0 # Count local IO
      OK_ERROR_CODES =[200, 301, 302]
   
      @@q = []
   
      def initialize(url)
        @url = url
      end
  
      def self.set_log(log)
       @@log = log
      end
    
      def self.shutdown
        if @@ios > 0 || @@writes > 0
           @@q <<  ->{self.shutdown} 
        else
            @@log.info("Stutting...")
            EM.stop
        end
      end
    
      def schedule(&block)
        if @@ios < MAX_IO && @@writes < MAX_WRITES
          block.call
        else
           @@q << block
        end
      end
      
      def inc_io
        @@log.debug "IOs: #{@@ios} -> #{@@ios + 1}"
        @@ios += 1
      end
  
      def dec_io
        @@log.debug "IOs: #{@@ios} -> #{@@ios - 1}"
        @@ios -= 1
        release
      end

      def inc_writes
        @@log.debug "Writes: #{@@writes} -> #{@@writes + 1}"
        @@writes += 1
      end
  
      def dec_writes
        @@log.debug "IOs: #{@@writes} -> #{@@writes - 1}"
        @@writes -= 1
        release
      end

      def release
        unless @@q.empty? || @@ios >= MAX_IO || @@writes >= MAX_WRITES
           @@q.pop.call
        end
      end
      
      protected :inc_io, :dec_io, :inc_writes, :dec_writes, :release, :schedule
      
      def fail(msg)
        super
        @@log.warn msg
      end
      
      # Non blocking get url
      def get
         schedule do
            inc_io
            @@log.info("Requesting: #{@url}")
            http = EM::HttpRequest.new(@url).get :redirects => 5
      
            http.callback do |h|
              succeed http.response
              dec_io
            end
    
            http.headers do |headers|
              unless OK_ERROR_CODES.include?(headers.status)
                fail("Error (#{headers.status}) with url:#{@url}")
                dec_io
              end
            end        
    
            http.errback do
              fail("Error downloading #{@url}")
              dec_io
            end       
          end
        self # Fluent interface
      end
  
      # Non blocking save file,
      # Pre: file exists before calling
      # Post: 'url' written to 'file' 
      def save(file)
          if File.exists? file
            fail "#{file} already exists. Skipping..."
          elsif Dir.exists? file
            fail "#{file} is a directory"
          else
            directory = file.split(File::SEPARATOR)[0...-1].join(File::SEPARATOR)
            Dir.mkdir directory unless Dir.exists? directory
      
            callback do |response|
              inc_writes
              EM::File::write(file, response) do |length|
                @@log.info "Saving: #{file} (#{length / 1024}KiB)"
                dec_writes  
              end
            end
            get
          end
       self # Fluent interface
      end

  end
    
end # Module WallLeecher