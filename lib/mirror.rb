# mirror.rb
#
# Author: Windix Feng <windix@gmail.com>
# License: GPL <http://www.gnu.org/licenses/gpl.html>
#
# mirror.rb is a ruby library to make local copy of a web page
# It's a clone of Chris Hagerman's Rorrim which is written in python
# http://github.com/webtreehouse/rorrim/tree/master

require 'open-uri'
require 'uri'
require 'logger'
require 'digest/md5'
require 'threadpool'
require 'fileutils'
require 'iconv'

#@logger = Logger.new(STDOUT)
#@logger.level = $DEBUG ? Logger::DEBUG : Logger::INFO

class Site
  MAX_LEVELS = 10
  USER_AGENT = "Mozilla/5.0 (compatible; mirror; ruby/#{RUBY_VERSION}/#{RUBY_PLATFORM})"
  NUMBER_OF_THREADS = 20

  attr_accessor :home_asset, :assets, :mirror_completed

  def initialize(source, destination, save = true, logger = Logger.new(STDOUT))
    @logger = logger
    #@logger.level = $DEBUG ? Logger::DEBUG : Logger::INFO
    
    @mirror_completed = false

    @destination = destination

    # setup assets hash and queue the initial asset
    @assets = {}

    if save && !valid_destination?
      @logger.error "Invalid destination #{destination}"
      return
    end

    @pool = ThreadPool.new(NUMBER_OF_THREADS)

    @logger.info "Mirroring #{source} to #{destination}"
    add_asset source, 1, true, nil
    
    @pool.shutdown

    @logger.debug "Queue is empty"

    @logger.debug "Total retrieved assets: #{@assets.select {|k, v| v.retrieved }.size }"
    
    @logger.debug "Update links"
    update_links

    if save
      @logger.debug "Saving assets"
      save_assets
    end

    if @assets.has_key?(source) && @assets[source].retrieved
      @logger.info "Mirroring is complete"
      @mirror_completed = true
      @home_asset = @assets[source]
    else
      @logger.error "Mirroring has failed"
    end
  rescue
    @logger.error "Mirroring has failed - #{$!.message}"
  end

  def valid_destination?
    if File.directory?(@destination)
      true
    else
      FileUtils.mkdir_p(@destination)
      @logger.debug "Dir #{@destination} created"
      true
    end
  rescue
    @logger.error "Failed to create dir #{@destination} - #{$!.message}"
    false
  end

  def add_asset(source, level, retrieve = false, referer = nil)
    unless @assets.has_key?(source)
      @logger.debug "Found #{source} Level ##{level}" if retrieve
      asset = Asset.new(source, @destination, level, USER_AGENT, referer, @logger)
      @assets[source] = asset
      
      if retrieve
        @logger.debug "Queued #{source}"
        
        #put into pool
        @pool.dispatch(asset) do |asset|
          process_asset(asset)
        end
      end
    end
  end

  def process_asset(asset)
    begin
      @logger.debug "Downloading #{asset.source}"
      asset.download
      @logger.info "Downloaded #{asset.source}"
      
      @assets[asset.source] = asset
      process_links asset
    rescue
      #@logger.error "Failed to download #{asset.source} - #{$!.message} in #{$!.backtrace}"
      @logger.error "Failed to download #{asset.source} - #{$!.message}"
    end
  end
    
  def process_links(asset)
    links = asset.get_links
    level = asset.level + 1
    referer = asset.source

    links.each do |source, link|
      if link.relation != :anchor && level < MAX_LEVELS
        add_asset source, level, true, referer
      elsif
        add_asset source, level, false, referer
      end
    end
  end

  def update_links
    @assets.each do |source, asset|
      if asset.retrieved
        asset.update_links(@assets)
      end
    end
  end

  def save_assets
    @assets.each do |source, asset|
      if asset.retrieved
        @logger.debug "Saving #{source}"
        asset.save source
      end
    end
  end
end

class Asset
  LINK_TYPES = {
    #:image => [/<\s*(img[^\>]*src\s*=\s*["']?([^"'\s>]*))/im, [:location, :url]],
    # :anchor => [/<\s*a[^\>]*(href\s*=\s*["']?([^"'\s>]*).*?>)(.*?)<\/a>/im, [:location, :url, :context]],
    :background => [/<\s*([body|table|th|tr|td][^\>]*background\s*=\s*["']?([^"'\s>]*))/im, [:location, :url]],
    #:input => [/<\s*input[^\>]*(src\s*=\s*["']?([^"'\s>]*))/im, [:location, :url]],
    :css => [/<\s*link[^\>]*stylesheet[^\>]*[^\>]*(href\s*=\s*["']?([^"'\s>]*))/im, [:location, :url]],
    :cssinvert => [/<\s*link[^\>]*(href\s*=\s*["']?([^"'\s>]*))[^\>]*stylesheet\s*/im, [:location, :url]],
    :cssimport => [/(@\s*import\s*u*r*l*\s*["'\(]*\s?([^"'\s\);]*))/im, [:location, :url]],
    :cssurl => [/(url\(\s*["']?([^"'\s\)]+))/im, [:location, :url]],
    #:javascript => [/<\s*script[^\>]*(src\s*=\s*["']?([^"'\s>]*))/im, [:location, :url]],
    :src => [/(src\s*=\s*["']?([^"'\s>]*))/im, [:location, :url]],
  }

  MIME_TYPES = {
    "text/css" => ".css",
    "image/gif" => ".gif",
    "text/html" => ".html",
    "image/jpeg" => ".jpg",
    "application/ecmascript" => ".js",
    "application/javascript" => ".js",
    "application/x-javascript" => ".js",
    "text/ecmascript" => ".js",
    "text/javascript" => ".js",
    "text/jscript" => ".js",
    "text/vbscript" => ".js",
    "image/png" => ".png",
    "text/plain" => ".txt",
  }

  attr_accessor :source, :destination, :level, :retrieved, :filename, 
    :hashcode, :extname, :page_title, :last_modified, :data

  def initialize(source, destination, level, user_agent, referer, logger)
    @source = escape_url(source)
    @destination = destination
    @level = level
    @user_agent = user_agent
    @referer = referer
    @logger = logger
    
    @retrieved = false
  end

  def download
    unless @retrieved
      # set user-agent and HTTP referer
      options = {}
      options["User-Agent"] = @user_agent
      options["Referer"] = @referer unless @referer.nil?
      
      # grub the data
      open(@source, options) do |f|
        @content_type = f.content_type
        @source = escape_url(f.base_uri.to_s)
        @charset = f.charset
        @last_modified = f.last_modified || Time.now
        @data = f.read
      end
      
      @base = get_base

      @filename = get_filename

      @page_title = get_page_title
      
      if @filename
        @destination = File.join(@destination, @filename)
        @retrieved = true
      end
    end
  end

  def escape_url(url)
    # escape url
    url = URI.escape(url)

    # unescape some special chars
    url.gsub! "%23", "#"
    url.gsub! "%25", "%"

    # remove fragments (parts started with #)  
    
    parts = URI.parse(url)
    
    # may be a bug in URI.parse: "#abc" can be parsed
    raise URI::InvalidComponentError if parts.host.nil?

    params = [parts.userinfo, parts.host, parts.port, parts.path, parts.query, nil]
    URI::HTTP.build(params).to_s
  
  rescue URI::InvalidComponentError
    url
  end

  # get base url of the page
  def get_base
    if @data =~ /<\s*base[^\>]*href\s*=\s*[\""\']?([^\""\'\s>]*).*?>/im
      # if base tag is set in the page, use it
      
      base = ($1[-1] == ?/) ? $1 : $1 + "/"
      
      # remove base tag
      @data.gsub!($&, "")
    
      base
    else
      # if not, get it from source url
      
      uri = URI.parse(@source)
      
      if uri.scheme == "http" 
        unless uri.path[-1] == ?/
          if pos = uri.path.rindex('/')
            uri.path = uri.path[0..pos]
          else
            uri.path = nil
          end
        end
        
        URI::HTTP.build([uri.userinfo, uri.host, uri.port, uri.path, nil, nil]).to_s
      else
        nil
      end
    end
  end

  def get_filename
    if MIME_TYPES.has_key?(@content_type)
      @hashcode = Asset.calculate_hashcode(@source)
      @extname = MIME_TYPES[@content_type]
      
      "#{@hashcode}_#{@last_modified.to_i}#{@extname}"
    end
  end

  def self.calculate_hashcode(source)
    Digest::MD5.hexdigest(source)
  end

  def get_page_title
    $1 if @extname == ".html" && @data =~ /<\s*title[^>]*>(.*?)<\/title>/im
  end

  def get_links
    @links = {}
    
    if [".html", ".css"].include?(@extname)
      @logger.debug "Getting linked assets in #{@source}"
      
      LINK_TYPES.each do |relation, details|
        re, match_names = *details
        
        @data.scan(re) do |matches|
          # build match data hash
          i = 0
          match_data = {}
          match_names.each { |k| match_data[k] = matches[i]; i += 1 }
          
          next if match_data[:url].empty?
          
          link = Link.new
          link.context = match_data[:context]  if match_data.has_key?(:context)
          link.location = match_data[:location]
          link.relation = relation

          link.original_source = match_data[:url]
          
          begin
            link.source = URI.join(@base, escape_url(match_data[:url])).to_s
          rescue
            @logger.warn "JOIN: '#{@base}', '#{match_data[:url]}'"
            next
          end

          @links[link.source] = link unless @links.has_key?(link.source)
        end
      end
    end

    @links
  end

  def update_links(assets)
    if @retrieved && [".html", ".css"].include?(@extname)
      @logger.debug "Updating links in #{@source}"

      @links.each do |source, link|
        if assets.has_key?(link.source)
          if link.location && link.original_source && assets[link.source].filename
            # puts "****** '#{link.location}' '#{link.original_source}' '#{assets[link.source].filename}'"
            
            s = link.location.sub(link.original_source, assets[link.source].filename)
            @data.sub!(link.location, s)
          end
        end
      end
    end
  end

  def save(source)
    if @retrieved
      if (source != @source)
        @logger.debug 'Skipped'
      else
        File.open(@destination, 'w') do |f|
          f.write(@data) 
        end
        @logger.debug "Saved #{@source} as #{@destination}"
      end
    end
  end

end

class Link
  attr_accessor :context, :location, :relation, :source, :original_source
end

if $0 == __FILE__
  if ARGV.size == 2
    url, output = *ARGV
    site = Site.new(url, output)
    puts "URL #{url} has been mirrored to #{site.home_asset.destination}" if site.home_asset
  else
    puts "Usage: mirror.rb [URL] [directory]"
  end
end

__END__

TODO:
  1. add / remove trailing slash on URL: http://www.wikipedia.org/
