class AddSharedToBookmarkSite < ActiveRecord::Migration
  def self.up
    add_column :bookmark_sites, :do_not_share, :integer, :length => 1
  end

  def self.down
    remove_column :bookmark_sites, :do_not_share
  end
end
