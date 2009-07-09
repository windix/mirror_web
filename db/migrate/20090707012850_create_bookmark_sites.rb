class CreateBookmarkSites < ActiveRecord::Migration
  def self.up
    create_table :bookmark_sites do |t|
      t.string :url
      t.string :title
      t.text :notes
      t.integer :home_asset_id

      t.timestamps
    end
  end

  def self.down
    drop_table :bookmark_sites
  end
end
