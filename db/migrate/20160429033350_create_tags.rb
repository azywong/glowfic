class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.integer :user_id, null: false
      t.string :name, null: false
      t.timestamps
    end
    add_index :tags, :name

    create_table :post_tags do |t|
      t.integer :post_id, null: false
      t.integer :tag_id, null: false
      t.boolean :suggested, default: false
      t.timestamps
    end
    add_index :post_tags, :post_id
    add_index :post_tags, :tag_id
  end
end
