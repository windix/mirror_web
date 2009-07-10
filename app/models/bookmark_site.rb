require 'mirror'

class BookmarkSite < ActiveRecord::Base
  acts_as_taggable
  
  # has_many :bookmark_assets, 
  #   :dependent => :delete_all #:destroy
  
  has_and_belongs_to_many :bookmark_assets,
    :join_table => 'bookmark_relations'

  belongs_to :home_asset, 
    :class_name => 'BookmarkAsset',
    :foreign_key => 'home_asset_id'

  belongs_to :user

  named_scope :all, :order => "updated_at DESC", :include => [ :home_asset, :user ]
  
  validates_presence_of :url
  validates_format_of :url, 
    :with => /^https?:\/\//

  def existing_site?
    @existing_site
  end

  def mirror_url
    home_asset ? home_asset.mirror_url : nil
  end
  
  def versions
    return [] unless home_asset
    
    sites = []
    home_asset.versions.each do |asset|
      sites << asset.site_use_this_as_home if asset.site_use_this_as_home 
    end

    sites
  end

  def self.per_page
    10
  end

  def save_bookmark
    @existing_site = false
    
    return false unless self.valid?

    # fetch web pages
    site = Site.new(url, ASSETS_ROOT, false, logger)

    if (site.mirror_completed)
      # update title
      self.title = "NO TITLE" if self.title.blank?
      
      if asset = BookmarkAsset.existing_asset?(site.home_asset) 
        @existing_site = true
        
        # update existing site's last update time
        asset.site_use_this_as_home.update_attributes!(
          :title => self.title,
          :notes => self.notes)
        
        true
      else
        # save site
        self.save!
          
        # save assets
        site.assets.each do |source, asset|
          if asset.retrieved
            asset.last_modified ||= Time.zone.at(0)
            
            unless bookmark_asset = BookmarkAsset.existing_asset?(asset)
              bookmark_asset = BookmarkAsset.create(
                :hashcode => asset.hashcode, 
                :extname => asset.extname,
                :last_modified => asset.last_modified)
              
              bookmark_asset.save_file(asset.data) if (source == asset.source)
            end
            
            bookmark_assets << bookmark_asset

            # update home_asset
            self.home_asset = bookmark_asset if (asset.hashcode == site.home_asset.hashcode)
          end
        end
        
        self.save!
        true
      end
    else
      errors.add_to_base("Failed to mirror the web page, please try again")
      false
    end
  
  rescue => exception
    logger.info exception
    errors.add_to_base("#{exception.message}, please try again")
    false
  end

  def self.group_bookmarks_by_date(bookmarks)
    groups = {}
    groups_order = []
    
    bookmarks.each do |bookmark|
      if bookmark
        date = bookmark.updated_at.to_s(:au_date)
        
        groups[date] ||= begin
                          groups_order << date; []
                         end

        groups[date] << bookmark
      end
    end
    
    [groups, groups_order]
  end

end
