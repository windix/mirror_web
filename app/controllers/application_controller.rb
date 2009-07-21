# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'delicious'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  include AuthenticatedSystem
  
  before_filter :delicious_init
  before_filter :set_locale

  protected
  def tag_cloud
    if logged_in?
      @tags = BookmarkSite.tag_counts :conditions => ['user_id = ?', current_user.id]
    else
      @tags = BookmarkSite.tag_counts :conditions => ['do_not_share = ?', 0]
    end
  end

  def tag_cloud_for_versions(bookmarks)
    ids = bookmarks.collect { |bookmark| bookmark.id }.join(",")
    @tags = BookmarkSite.tag_counts :conditions => "bookmark_sites.id in (#{ids})"
  end

  def delicious_init
    config = YAML::load(File.read(File.join(RAILS_ROOT, 'config', 'delicious.yml')))
    @delicious = Delicious.new(config['username'], config['password'], logger)
  end

  def set_locale
    # priority from high to low:
    # - user's preference (via session)
    # - url params
    # - browser's header
    # - default

    session[:locale] = params[:locale] if params[:locale]

    if session[:locale]
      I18n.locale = session[:locale]
    elsif extract_locale_from_accept_language_header
      I18n.locale = extract_locale_from_accept_language_header
    else
      I18n.locale = I18n.default_locale
    end

=begin    
    I18n.backend.store_translations 'en', :version => {
      :one => '1 version',
      :other => '{{count}} versions'
    }

    I18n.backend.store_translations 'zh', :version => {
      :one => '{{count}}个版本',
      :other => '{{count}}个版本'
    }
=end

#    session[:locale] = params[:locale] if params[:locale]
#    I18n.locale = session[:locale] || I18n.default_locale

#    locale_path = "#{LOCALES_DIRECTORY}#{I18n.locale}.yml"

#    unless I18n.load_path.include? locale_path
#      I18n.load_path << locale_path
#      I18n.backend.send(:init_translations)
#    end
    
#  rescue Exception => err
#    logger.error err
#    flash.now[:notice] = "#{I18n.locale} translation not available"

#    I18n.load_path -= [locale_path]
#    I18n.locale = session[:locale] = I18n.default_locale
  end

#  def default_url_options(options = {})
#    logger.debug "default_url_options is passed options: #{options.inspect}\n"
#    { :locale => I18n.locale }
#  end

  def extract_locale_from_accept_language_header
    logger.debug "* Accept-Language: #{request.env['HTTP_ACCEPT_LANGUAGE']}"
    @header_locale ||= request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
  end

end
