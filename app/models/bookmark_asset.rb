class BookmarkAsset < ActiveRecord::Base
  has_and_belongs_to_many :bookmark_sites,
    :join_table => 'bookmark_relations'
  
  has_many :site_use_this_as_home,
    :class_name => 'BookmarkSite',
    :foreign_key => 'home_asset_id'

  def mirror_url
    File.join("/assets", filename)
  end

  def filename
    "#{hashcode}_#{last_modified.to_i}#{extname}"
  end

  def save_file(data)
    destination = File.join(ASSETS_ROOT, filename)
    
    File.open(destination, 'w') do |f|
      f.write(data) 
    end

    logger.info "#{destination} saved!"
  end

  def self.existing_asset?(asset)
    BookmarkAsset.find_by_hashcode_and_last_modified(
      asset.hashcode, asset.last_modified.in_time_zone)
  end
end
