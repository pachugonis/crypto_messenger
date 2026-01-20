class CreateFolders < ActiveRecord::Migration[8.1]
  def change
    create_table :folders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.references :parent_folder, foreign_key: { to_table: :folders }

      t.timestamps
    end

    add_index :folders, [ :user_id, :parent_folder_id, :name ], unique: true
  end
end
