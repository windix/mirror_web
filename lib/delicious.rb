require 'rubygems'
require 'rest_client'
require 'rexml/document'
require 'logger'

class Delicious
  def initialize(username, password, logger = Logger.new($stdout))
    @username = username
    @password = password
    @logger = logger

    @base_url = "https://#{@username}:#{@password}@api.del.icio.us/v1/"
  end

  def suggest_tags(url) 
    tags = []
    
    request_url = "#{@base_url}posts/suggest?url=#{url}"
    
    result = RestClient.get request_url

    doc = REXML::Document.new(result)
    REXML::XPath.each(doc, "/suggest/popular") { |element| tags << element.text }
    tags
  
  rescue => e
    @logger.error "Delicious ERROR: e.message"
    []
  end
end
