class AddFetchedToBookmarkSites < ActiveRecord::Migration
  def self.up
    add_column :bookmark_sites, :fetch_status, :string, :default => 'UNFETCHED'
    BookmarkSite.update_all("fetch_status = 'FETCHED'")
  end

  def self.down
    remove_column :bookmark_sites, :fetch_status
  end
end
