require 'rchardet'
require 'delicious'
require 'iconv'
require 'open-uri'

class RestUtils

=begin  
  def self.get_page_title(url)
    # TODO: user_agent
    # content = RestClient.get(url, :accept => "*/*") 
    content = open(url).read   

    if content =~ /<\s*title[^>]*>(.*?)<\/title>/im
      title = $1.strip

      debugger
      cd = CharDet.detect(title)
      encoding = cd['encoding']
      encoding = "GBK" if encoding == "GB2312" 
      title = Iconv.iconv('UTF8', encoding, title).to_s.strip
      
      puts "encoding=#{encoding} title=*#{title}*"

      title
    end
  end
=end

  def self.guess_encoding(content)
    #RestClient.post "http://localhost:3000/services/guess", :content => content
    RestClient.post "http://localhost:#{SERVICES_PORT}/guess", :content => content
  end

  def self.get_page_title(url)
    # TODO: user_agent
    content = RestClient.get(url, :accept => "*/*") 

    if content =~ /<\s*title[^>]*>(.*?)<\/title>/im
      title = $1.strip
      encoding = guess_encoding(title)
      encoding = "GBK" if encoding == "GB2312"
      title = Iconv.iconv('UTF8', encoding, title).to_s unless encoding == "utf-8"

      puts "encoding=#{encoding} title=*#{title}*"

      title
    end
  end

end
