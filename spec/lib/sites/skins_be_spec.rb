# Wall-leecher Wallpaper downloader
# © 2011 Dharmesh Malam
# ISC License

# skins_be_spec.rb

$LOAD_PATH << '../../sites'
require 'skins_be.rb'
require 'ostruct'

describe WallLeecher::Skins_be do
  
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
      subject { WallLeecher::Skins_be }
    
      it "responds to site_params" do
        subject.should_receive(:site_params)
        subject.site_params
      end
      
      
      it "gives default site params" do
        
        params = subject.site_params
        params.keys.length.should eq(1)
        params.should include('skins.be')
        
      end
      
    end
    
    describe 'to_s' do
      it "returns a string" do
        WallLeecher::Skins_be.to_s.length.should be
        
      end
    end
    
  
end