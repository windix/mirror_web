# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  include AuthenticatedSystem
  
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
end
