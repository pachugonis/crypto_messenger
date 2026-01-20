class CreateMessageReads < ActiveRecord::Migration[8.1]
  def change
    create_table :message_reads do |t|
      t.references :message, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :read_at, null: false

      t.timestamps
    end
    
    add_index :message_reads, [:message_id, :user_id], unique: true
    add_index :message_reads, :read_at
  end
end
