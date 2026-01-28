class CreateAdvertisements < ActiveRecord::Migration[8.1]
  def change
    create_table :advertisements do |t|
      t.string :title, null: false
      t.text :content
      t.string :image_url
      t.string :link
      t.integer :position, default: 0, null: false
      t.boolean :active, default: true, null: false
      t.string :icon_type, default: 'svg'
      t.string :icon_color

      t.timestamps
    end
    
    add_index :advertisements, :position
    add_index :advertisements, :active
  end
end
