require 'test/unit'
require File.dirname(__FILE__) + "/../../lib/url_utils"

class URLUtilsTest < Test::Unit::TestCase
  def test_validate_and_format_url
    valid_urls = [
      "http://www.google.com",
      "https://www.google.com",
      "http://zh.wikipedia.org/w/index.php?title=M249班用自動武器&variant=zh-cn",
      "http://zh.wikipedia.org/w/index.php?title=穆罕默德·乌尔德·阿卜杜勒－阿齐兹&variant=zh-cn",
    ]

    valid_urls.each do |url|
      assert_not_equal nil, URLUtils.validate_and_format_url(url)
      url_without_scheme = url.sub(/^https?:\/\//, '')
      assert_not_equal nil, URLUtils.validate_and_format_url(url_without_scheme)
    end

    invalid_urls = [
      "ftp://www.google.com",
      "localhost:8080",
      "  ",
    ]

    invalid_urls.each do |url|
      assert_equal nil, URLUtils.validate_and_format_url(url)
    end

  end
end
