class CreateBookmarkAssets < ActiveRecord::Migration
  def self.up
    create_table :bookmark_assets do |t|
      t.integer :bookmark_site_id
      t.string :hashcode
      t.string :extname

      t.timestamps
    end
  end

  def self.down
    drop_table :bookmark_assets
  end
end
