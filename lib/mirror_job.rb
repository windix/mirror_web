require 'mirror'

class MirrorJob < Struct.new(:site_id)
  def perform
    bookmark_site = BookmarkSite.find(site_id)
    
    # fetch web pages
    site = Site.new(bookmark_site.url, ASSETS_ROOT, false, Rails.logger)

    if (site.mirror_completed)
      bookmark_site.fetch_status = "FETCHED"
      
      # save assets
      site.assets.each do |source, asset|
        if asset.retrieved
          unless bookmark_asset = BookmarkAsset.existing_asset?(asset)
            bookmark_asset = BookmarkAsset.create(
              :hashcode => asset.hashcode, 
              :extname => asset.extname,
              :last_modified => asset.last_modified)
            
            bookmark_asset.save_file(asset.data) if (source == asset.source)
          end
          
          bookmark_site.bookmark_assets << bookmark_asset

          # update home_asset
          bookmark_site.home_asset = bookmark_asset if (asset.hashcode == site.home_asset.hashcode)
        end
      end
    else
      bookmark_site.fetch_status = "FAILED"
    end
  rescue => exception
    Rails.logger.info exception
    bookmark_site.fetch_status = "FAILED"
  ensure
    bookmark_site.save!
  end
end