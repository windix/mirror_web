class AddBookmarksRelation < ActiveRecord::Migration
  def self.up
    create_table :bookmark_relations, :id => false do |t|
      t.integer :bookmark_site_id
      t.integer :bookmark_asset_id
    end
    remove_column :bookmark_assets, :bookmark_site_id
  end

  def self.down
    drop_table :bookmark_relations
    add_column :bookmark_assets, :bookmark_site_id, :integer
  end
end
