#!/usr/bin/env ruby
# Wall-leecher Wallpaper downloader
# © 2011 Dharmesh Malam
# FreeBSD License

require 'ostruct'
require 'eventmachine'
require 'em-http'
require "em-files"
require 'logger'

module WallLeech

  class Leecher

    attr_accessor :options

    def initialize(options, log)
      @options = options
      @log = log
      Fetcher::set_log(log)
    end
      
    def reactor
      EM.run do
        Signal.trap("TERM") do @q << shutdown end
        @log.info("Starting...")
        yield
      end
    end # reactor
    
    def shutdown
      # This may not always work as empty is approx!!!  
      if Fetcher.outstanding?
          EM::next_tick {shutdown} 
        else
          @log.info("Stutting...")
          EM.stop
        end
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
      MAX_IO = 6  # Max number of concurrent IOs
      @@ios = 0   # Count IO requests
     def initialize(url)
        @url = url
      end

    def schedule(&block)
      if @@ios <= MAX_IO
        @@log.debug('++'); block.call ; @@log.debug('--');
      else
         EM::next_tick {schedule &block} 
      end
    end
    
    def self.set_log(log)
      @@log ||= log
    end
        
    def inc_io
      @@log.debug "IOs: #{@@ios} -> #{@@ios +1}"
      @@ios += 1
    end
    
    def dec_io
      @@log.debug "IOs: #{@@ios} -> #{@@ios -1}"
      @@ios -= 1
    end
    
    def self.outstanding?
      @@ios > 0
    end
    
    # Non blocking get url
    def get
       schedule do
          inc_io
          @@log.info("Getting: #{@url}")
          http = EM::HttpRequest.new(@url).get :redirects => 5
        
          http.callback do |h|
            succeed http.response
          end
      
          http.headers do |headers|
            fail("Error (#{headers.status}) with url:#{@url}") unless headers.status == 200 || headers.status == 301
          end        
      
          http.errback do
            fail("Error downloading #{@url}")
          end       
        end
      self 
    end
    
    # Non blocking save file,
    # Pre: file exists before calling
    # Post: 'url' written to 'file' 
    def save(file)
      schedule do
        inc_io
        @@log.info "Getting: #{@url}"
        if File.exists? file
          fail "#{file} already exists. Skipping..."
        elsif Dir.exists? file
          fail "#{file} is a directory"
        else
          directory = file.split(File::SEPARATOR)[0...-1].join(File::SEPARATOR)
          Dir.mkdir directory unless Dir.exists? directory
        
          self.callback do |response|
            EM::File::write(file, response) do |length|
              @@log.info "Saving: #{file} (#{length / 1024}KiB)"
            end
          end
                   
            @@log.info("Getting: #{@url}")
            http = EM::HttpRequest.new(@url).get :redirects => 5
           
            http.callback do |h|
              succeed http.response
            end
                    
            http.headers do |headers|
              fail("Error (#{headers.status}) with url:#{@url}") unless headers.status == 200 || headers.status == 301
            end        
                    
            http.errback do
              fail("Error downloading #{@url}")
            end                  
        end
      
      end
      self
    end
  
    def fail(msg)
      super
      @@log.warn msg
      dec_io    
    end
    
    def succeed(*args)
      super 
      dec_io
    end
    
  end
  
  
end # Module WallLeech