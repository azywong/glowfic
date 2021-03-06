class AddTagTypes < ActiveRecord::Migration
  def change
    add_column :tags, :type, :string
    add_index :tags, :type

    create_table :character_tags do |t|
      t.integer :character_id, null: false
      t.integer :tag_id, null: false
      t.timestamps
    end
    add_index :character_tags, :character_id
    add_index :character_tags, :tag_id
  end
end
