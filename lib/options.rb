# Wall-leecher Wallpaper downloader
# © 2011 Dharmesh Malam
# ISC License

require 'nokogiri'
require 'open-uri'
require 'optparse'
require 'ostruct'
require 'rbconfig'

module WallLeecher

  class Options
  
    BANNER = "Usage: wall-leech.rb SITE [options] [site-options]"
    
    def self.version
      [0,2,2]
    end
    
    def self.default_resolution
      "1920x1200"
    end
    
    attr_accessor :sites
  
    def initialize(sites)
      @sites = sites
    end

    def parse_options(argv)
      
      begin
      
        site = argv.slice(0)
        raise ArgumentError, "Unknown site. Choose from: #{site_names}" unless site && 
                                                                               !site.start_with?('-') &&
                                                                               (site_names.any?do |s| s =~ /#{site}/i end)
    
        options = default_options
        options.site = (site_names.find do |s| s =~ /#{site}/i end).to_sym
        options.output = File.join(default_output, site)
        params = default_site_options(options.site)
      
        opts = OptionParser.new do |opts|
          opts.banner = BANNER
          opts.separator  "Choose [SITE] from: #{site_names}"
          opts.separator  ""
          opts.separator "Options:"

          opts.on("-o", "--output [DIR]", String,
                  "Directory to save the wallpapers. Default:" + File.join(default_output, "#{options.site}").to_s) do |o|
            raise ArgumentError, "Output (#{o}) not an directory" unless o && Dir.exists?(o)
            options.output = o
          end
    
          opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
            options.verbose = v
          end

          opts.on("-d", "--debug", "Run in debug mode") do |d|
            options.debug = d
          end

          opts.separator ""
          opts.separator "Common options:"

          opts.on("-h", "--help", "Show this message") do
            puts opts
            exit
          end

          opts.on("--version", "Show version") do
            puts version.join(".")
            exit
          end  
          
           opts.separator ""
           opts.separator "Site options: #{options.site.to_s}"

           sites[options.site].each_pair do |k, v|
            if v[:type]
               opts.on(v[:cmd], v[:long_cmd], v[:type], v[:desc] + "\tDefault: " + v[:default].to_s) do |p|
                raise ArgumentError, "Error with #{v[:cmd]}, #{v[:long_cmd]}:\t#{v[:error]}" unless v[:validate].call(p)
                 params[k] = p
               end 
              else
                opts.on(v[:cmd], v[:long_cmd], v[:desc] + "\tDefault: " + v[:default].to_s) do |p|
                  params[k] = p
                end
              end
           end
               
        end.parse!(argv)
        
      rescue ArgumentError, OptionParser::InvalidOption => e
        puts BANNER
        puts e.message
        exit
      end
      
      options.params = OpenStruct.new(params)
      options
  
    end
    
    protected
  
      def default_output
        case Config::CONFIG['host_os']
          when /darwin/i
            File.expand_path('~/Pictures/wallpaper')
          when /mswin|windows/i
            File.expand_path('~\Pictures\wallpaper')
          when /linux/i
            File.expand_path('~/wallpaper')
          else
            File.expand_path('~/wallpaper')
        end
      end

      def default_options
        options = OpenStruct.new
        options.site = @sites.keys.first
        options.output = File.join(default_output, options.site.to_s)
        options.verbose = true
        options.debug = false
        options.params = nil
        options
      end
  
      def site_names
        @sites.keys.map &:to_s 
      end
  
      def default_site_options(site)
        params ={}
        sites[site].each_pair do |k, v|
          params[k] = v[:default]
        end
        params
      end

  end # End Options
end # End WallLeecher