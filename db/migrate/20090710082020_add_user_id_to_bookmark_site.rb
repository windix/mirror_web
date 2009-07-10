class AddUserIdToBookmarkSite < ActiveRecord::Migration
  def self.up
    add_column :bookmark_sites, :user_id, :integer
  end

  def self.down
    remove_column :bookmark_sites, :user_id
  end
end
