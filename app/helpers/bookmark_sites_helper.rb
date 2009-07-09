module BookmarkSitesHelper
  def bookmarklet
    # TODO
    "javascript:(function(){f='http://localhost:3000/bookmark_sites/new?url='+encodeURIComponent(window.location.href)+'&title='+encodeURIComponent(document.title);a=function(){location.href=f};if(/Firefox/.test(navigator.userAgent)){setTimeout(a,0)}else{a()}})()"
  end
  
  def versions(site)
    pluralize site.versions.size, "version"
  end
end
