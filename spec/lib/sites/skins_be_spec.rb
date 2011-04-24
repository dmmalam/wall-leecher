# Wall-leecher Wallpaper downloader
# © 2011 Dharmesh Malam
# ISC License

# skins_be_spec.rb

path = File.expand_path(File.join(File.dirname(__FILE__), '../../../lib/sites'))
$LOAD_PATH.unshift path unless $LOAD_PATH.include? path

require 'skins_be'
require 'ostruct'

describe WallLeecher::Sites::SkinsBe do
  
  # before(:each) do
  #   options = OpenStruct.new
  #   options.site = 'Skins.be'
  #   options.output = '~/'
  #   options.resolution = "1920x1200"
  #   options.verbose = false
  #   options.params = nil
  #   
  #   @skins_be = WallLeecher::Skins_be.new ()
  # end
  
    describe 'site_param' do
      subject { WallLeecher::Sites::SkinsBe }
    
      it "responds to site_params" do
        subject.should_receive(:site_params)
        subject.site_params
      end
      
      
      it "gives default site params" do
        
        params = subject.site_params
        params.keys.length.should be
  
      end
      
    end
    
    describe 'to_s' do
      it "returns a string" do
        WallLeecher::Sites::SkinsBe.to_s.length.should be
        
      end
    end
    
  
end