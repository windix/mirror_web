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
  
  named_scope :all_for_user, lambda { |user| 
    { :conditions => ['user_id = ?', user.id],
      :order => "updated_at DESC", :include => [ :home_asset, :user ] }
  }

  validates_presence_of :url
  validates_format_of :url, :with => /^https?:\/\//

  def mirror_url
    home_asset ? home_asset.mirror_url : nil
  end
 
  def self.per_page
    10
  end

  def existing_site?
    ! @existing_site.nil?
  end

  def save_bookmark
    return false unless self.valid?

    # fetch web pages
    site = Site.new(url, ASSETS_ROOT, false, logger)

    if (site.mirror_completed)
      # update title
      self.title = "NO TITLE" if self.title.blank?
      
      if @existing_site = find_existing_site?(site.home_asset)
        
        # update existing site's last update time
        @existing_site.update_attributes!(
          :title => self.title,
          :notes => self.notes,
          :updated_at => Time.zone.now)
        
        true
      else
        # save site
        self.save!
          
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

  def versions
    BookmarkSite.find_by_sql(['SELECT site.* FROM bookmark_sites as site inner join bookmark_assets as asset on site.home_asset_id = asset.id WHERE asset.hashcode = ? ORDER BY asset.last_modified DESC', self.home_asset.hashcode]) if self.home_asset
  end

  private

  def find_existing_site?(asset)
    results = BookmarkSite.find_by_sql(['SELECT site.* FROM bookmark_sites as site inner join bookmark_assets as asset on site.home_asset_id = asset.id WHERE asset.hashcode = ? and asset.last_modified = ? and site.user_id = ?', 
                          asset.hashcode, asset.last_modified.in_time_zone, self.user_id])
    return results[0] unless results.size == 0
  end
end
