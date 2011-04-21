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
   
    MAX_IO = 6  # Max number of concurrent IOs
    
    attr_accessor :options

    def initialize(options, log)
      @options = options
      @log = log
      @q = EM::Queue.new  # queue of IO blocks to execute
      @ios = 0            # count IO requests
    end
      
    def reactor
      EM.run do
          
          cb = proc do |block|
              # Only pop off if current outstadings IO <= max IO
              if @ios <= MAX_IO
                @log.debug('++'); block.call;@log.debug('--');
                @q.pop cb # Re-register callback 
              else
                block
                 EM::next_tick {cb.call(block)}
              end
           end
        
        @q.pop cb # Register callback
        
        Signal.trap("TERM") do @q << shutdown end
        
        @log.info("Starting...")
      end
    end # reactor
    
    def shutdown
      lambda do
      # This may not always work as empty is approx!!!  
      unless @q.empty? && @ios == 0
          EM::next_tick shutdown 
        else
          @log.info("Stutting...")
          EM.stop
        end
      end
    end  
    
    def inc_io
      @ios += 1
    end
    
    def dec_io
      @ios -= 1
    end
          
    protected
      # Pure function to create correct filename
      def prep_file(url, dir)
        parts = url.split('/')
        File.join(dir, parts[-1])
      end
    
      # Non blocking get url
      def get_url(url, &block)
        lambda do
          inc_io
          @log.info("Getting: #{url}")
          http = EM::HttpRequest.new(url).get :redirects => 5
          
          http.callback do |h|
            block.call http.response
            dec_io
          end
        
          http.headers do |headers|
            self.fail("Error (#{headers.status}) with url:" + url) unless headers.status == 200 || headers.status == 301
          end        
        
          http.errback do
            self.fail("Error downloading #{url}")
          end        
        end
      end
      
      # Non blocking save file,
      # Pre: file exists before calling
      # Post: 'url' written to 'file' 
      def save_file(url, file)
        lambda do
          inc_io
          @log.info "Getting: #{url}"
        
          if File.exists? file
            self.fail "#{file} already exists. Skipping..."
          elsif Dir.exists? file
            self.fail "#{file} is a directory"
          else
            directory = file.split(File::SEPARATOR)[0...-1].join(File::SEPARATOR)
            Dir.mkdir directory unless Dir.exists? directory
          
            pipe = EM::HttpRequest.new(url).get :keepalive => true, :redirects => 5

            pipe.headers do |headers|
              self.fail "Error (#{headers.status}) with url: #{url}" unless headers.status == 200 || headers.status == 301
            end

            pipe.errback do
              self.fail "Error downloading #{file}"
            end
     
            pipe.callback do |http|
              EM::File::write(file, http.response) do |length|
                @log.info "Saving: #{file} (#{length / 1024}KiB)"
                dec_io
              end
            end
          
          end
        end
      end
    
      def fail(msg)
        @log.warn msg
        @ios -= 1            
      end
    
  end # Class Leecher
end # Module WallLeach