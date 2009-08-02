require 'rest_client'
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

  named_scope :all, :order => "updated_at DESC", :conditions => ['do_not_share = ?', 0], :include => [ :home_asset, :user ]
  
  named_scope :all_for_user, lambda { |user| 
    { :conditions => ['user_id = ?', user.id],
      :order => "updated_at DESC", :include => [ :home_asset, :user ] }
  }

  validates_presence_of :url
  validates_format_of :url, :with => /^https?:\/\//

  def mirror_url
    home_asset.mirror_url if home_asset
  end
 
  def self.per_page
    10
  end

  def last_modified
    home_asset.last_modified if home_asset
  end

  def self.group_bookmarks_by_date(bookmarks, sort_date_by = :updated_at)
    groups = {}
    groups_order = []
    
    bookmarks.each do |bookmark|
      if bookmark
        #date = bookmark.updated_at.to_s(:au_date)
        date = I18n.l(bookmark.send(sort_date_by).to_date, :format => :long)

        groups[date] ||= begin
                          groups_order << date; []
                         end

        groups[date] << bookmark
      end
    end
    
    [groups, groups_order]
  end

  def versions(user)
    return [] unless self.home_asset
    bookmarks = BookmarkSite.find_by_sql(['SELECT site.* FROM bookmark_sites as site inner join bookmark_assets as asset on site.home_asset_id = asset.id WHERE asset.hashcode = ? ORDER BY asset.last_modified DESC', self.home_asset.hashcode]) if self.home_asset

    unless user.nil?
      # remove all other user's 'do_not_share' items
      bookmarks.reject { |bookmark| bookmark.do_not_share == 1 && bookmark.user_id != user.id }

    else
      # remove all 'do_not_share' items
      bookmarks.reject { |bookmark| bookmark.do_not_share == 1 }
    end
  end

  def self.version_exists?(url, user_id)
    #TODO user-agent
    
    response = RestClient.head(url, :accept => '*/*')
    
    last_modified = if v = response.headers[:last_modified] 
                      Time.httpdate(v)
                    else
                      Time.now
                    end

    hashcode = Asset.calculate_hashcode(response.url)

    results = BookmarkSite.find_by_sql(['SELECT site.* FROM bookmark_sites as site inner join bookmark_assets as asset on site.home_asset_id = asset.id WHERE asset.hashcode = ? and asset.last_modified = ? and site.user_id = ?', 
                          hashcode, last_modified.in_time_zone, user_id])
    return results[0] unless results.size == 0
  end
end
