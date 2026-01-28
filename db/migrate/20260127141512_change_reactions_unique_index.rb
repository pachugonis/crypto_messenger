class ChangeReactionsUniqueIndex < ActiveRecord::Migration[8.1]
  def change
    # Remove old index that allowed multiple reactions per user
    remove_index :reactions, [:message_id, :user_id, :emoji], unique: true
    
    # Clean up duplicates - keep only the latest reaction for each user per message
    reversible do |dir|
      dir.up do
        execute <<-SQL
          DELETE FROM reactions
          WHERE id NOT IN (
            SELECT MAX(id)
            FROM reactions
            GROUP BY message_id, user_id
          )
        SQL
      end
    end
    
    # Add new index that allows only one reaction per user per message
    add_index :reactions, [:message_id, :user_id], unique: true
  end
end
