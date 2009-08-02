module BookmarkSitesHelper
  def bookmarklet
    "javascript:(function(){f='#{WEBSITE_URL}/bookmarks/new?url='+encodeURIComponent(window.location.href)+'&title='+encodeURIComponent(document.title);a=function(){location.href=f};if(/Firefox/.test(navigator.userAgent)){setTimeout(a,0)}else{a()}})()"
  end
  
  def versions_tag(site)
    #pluralize site.versions(current_user).size, t("bookmarks.version")
    t 'bookmarks.version', :count => site.versions(current_user).size
  end
  
  def mirror_url_tag(site)
    if site.home_asset
      link_to site.title, site.mirror_url
    else
      site.title
    end
  end
  
  def fetch_status_tag(site)
    case site.fetch_status
    when "FETCHED":
      site.updated_at.to_s(:time_only)
    when "UNFETCHED":
      t('bookmarks.status_in_progress')
    when "FAILED":
      t('bookmarks.status_failed_to_fetch')
    end
  end
end
