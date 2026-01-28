class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :message, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.datetime :deleted_at

      t.timestamps
    end
    
    add_index :comments, :deleted_at
    add_index :comments, [:message_id, :created_at]
  end
end
