class AddLastModifiedToBookmarkAssets < ActiveRecord::Migration
  def self.up
    add_column :bookmark_assets, :last_modified, :datetime 
  end

  def self.down
    remove_column :bookmark_assets, :last_modified
  end
end
