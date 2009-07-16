require 'rchardet'
require 'open-uri'
require 'iconv'

#url = "http://www.google.com"
#url = "http://www.baidu.com"
#url = "http://www.baidu.jp"
#url = "http://6park.com"
url = "http://kiwi.csie.chu.edu.tw/blog/archives/138"
#url = "http://www.cwb.gov.tw/V6/index.htm"
#url = "http://bbs.6park.com/bbs2/messages/8407.html"

=begin
content = open(url).read
if content =~ /<\s*title[^>]*>(.*?)<\/title>/im
  cd = CharDet.detect($1)
  encoding = cd['encoding']
  encoding = "GBK" if encoding == "GB2312" 
  title = Iconv.iconv('UTF8', encoding, $1).to_s.strip

  puts encoding
  puts "*#{title}*"
else
  puts "NO TITLE!"
end
=end

def get_page_title(url)
  # TODO: user_agent
  # content = RestClient.get(url, :accept => "*/*") 
  # content = open(url).read
  content = "<title>\r\n\t  \345\225\206\346\245\255\346\234\215\345\213\231\347\232\204Ruby on Rails HTTP Cluster\350\247\200\345\277\265\345\217\212\346\270\254\350\251\246 &raquo; Kiwi\346\240\274\347\266\262\346\212\200\350\241\223\351\226\213\347\231\274\347\253\231\t\r\n</title>"

  if content =~ /<\s*title[^>]*>(.*?)<\/title>/im
    title = $1.strip

    cd = CharDet.detect(title)
    encoding = cd['encoding']
    encoding = "GBK" if encoding == "GB2312"
    title = Iconv.iconv('UTF8', encoding, title).to_s.strip

    puts "encoding=#{encoding} title=*#{title}*"

    title
  end
end

puts get_page_title(url)

