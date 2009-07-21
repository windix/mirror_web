module BookmarkSitesHelper
  def bookmarklet
    "javascript:(function(){f='#{WEBSITE_URL}/bookmarks/new?url='+encodeURIComponent(window.location.href)+'&title='+encodeURIComponent(document.title);a=function(){location.href=f};if(/Firefox/.test(navigator.userAgent)){setTimeout(a,0)}else{a()}})()"
  end
  
  def versions_tag(site)
    #pluralize site.versions(current_user).size, t("bookmarks.version")
    t 'bookmarks.version', :count => site.versions(current_user).size
  end
end
