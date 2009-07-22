require 'uri'

class URLUtils
  # validate if the url uses http(s) scheme
  # add "http://" to url when necessary
  # return stripped url result (but unescaped)
  def self.validate_and_format_url(url)
    unless url.nil?
      url.strip!
      escaped_url = URLUtils.escape_url(url)
      
      case URI.parse(escaped_url).scheme
      when /http?/
        url
      when nil
        "http://#{url}" if URI.parse("http://#{escaped_url}").is_a? URI::HTTP
      end
    end
  rescue URI::InvalidURIError
  end

  def self.escape_url(url)
    # escape url
    url = URI.escape(url)

    # unescape some special chars
    url.gsub! "%23", "#"
    url.gsub! "%25", "%"

    url
  end
end
