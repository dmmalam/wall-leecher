# © 2011 Dharmesh Malam
# FreeBSD License

require 'nokogiri'
require 'open-uri'

SKINS_TAG_URL = 'http://www.skins.be/tags/'

def get_last_page(resolution)
  url = SKINS_TAG_URL + params[:resolution]
  doc = Nokogiri::HTML(open(url))
  
  last_url = doc.xpath('//*[@alt="the last"]').first.parent['href']
  last_url.scan(/\d+/).last.to_i
end

def fetch_pages(params)
  page_url = SKINS_TAG_URL + params[:resolution] + '/page'
  
  params[:start].upto(params[:last]) do |page|
    page_doc = Nokogiri::HTML(open(page_url + '/' + page.to_s))

    as = page_doc.search('a') 
    links = as.find_all do |a| a['href'] =~ /wallpaper.skins.be.*#{params[:resolution]}.*/ end

    links.each do |l|
      link = adjust_link l['href'] 
      save_file link, params[:output_dir]  
    end
  
  end

end

def adjust_link(link)
    parts = link.split('/')
    
    pic = parts[3] + '-' + parts[5] + '-' + parts[4] +'.jpg'
    parts[2] = "wallpapers.skins.be"

    (parts[0..3] << pic).join('/')

end

def save_file(url, dir)
  uri = URI.parse(url)
  parts = url.split('/')
  puts url
  Net::HTTP.start( uri.host ) { |http|
    resp = http.get( uri.path )
    open( dir +'/' + parts[4], 'wb' ) { |file|
      file.write(resp.body)
    }
  }
  
end

def start

  options = { :start => 1,
              :last => 4,
              :output_dir => File.expand_path('~/skins'),
              :resolution =>'1920x1200'
            }
            
  fetch_pages options
  
end

start