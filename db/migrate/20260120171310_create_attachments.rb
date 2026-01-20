class CreateAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :attachments do |t|
      t.references :attachable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.string :access_token
      t.datetime :access_token_expires_at

      t.timestamps
    end

    add_index :attachments, :access_token, unique: true
  end
end
