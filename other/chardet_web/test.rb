require 'rubygems'
require 'rest_client'
require 'iconv'

def guess_encoding(content)
  RestClient.post "http://localhost:9393/guess", :content => content
end

def get_page_title(url)
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

#url = "http://www.google.com"
#url = "http://www.baidu.com"
#url = "http://www.baidu.jp"
#url = "http://6park.com"
url = "http://kiwi.csie.chu.edu.tw/blog/archives/138"
#url = "http://www.cwb.gov.tw/V6/index.htm"
#url = "http://bbs.6park.com/bbs2/messages/8407.html"

puts get_page_title(url)
