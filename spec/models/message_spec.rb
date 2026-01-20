require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'validations' do
    it 'is valid with content' do
      message = build(:message)
      expect(message).to be_valid
    end

    it 'requires content' do
      message = build(:message, content: nil)
      expect(message).not_to be_valid
    end
  end

  describe 'encryption' do
    it 'encrypts content when saved' do
      user = create(:user)
      room = create(:room)
      create(:room_participant, user: user, room: room)
      
      message = create(:message, room: room, user: user, content: 'Secret message')
      
      # Verify content is accessible as plaintext through model
      expect(message.content).to eq('Secret message')
      
      # Verify content is encrypted in database
      raw_content = ActiveRecord::Base.connection.execute(
        "SELECT content FROM messages WHERE id = #{message.id}"
      ).first['content']
      
      expect(raw_content).not_to eq('Secret message')
      expect(raw_content).to include('{') # Encrypted content is JSON
    end

    it 'decrypts content when read' do
      user = create(:user)
      room = create(:room)
      
      message = create(:message, room: room, user: user, content: 'Another secret')
      
      # Reload from database
      loaded_message = Message.find(message.id)
      expect(loaded_message.content).to eq('Another secret')
    end
  end

  describe 'soft delete' do
    it 'can be soft deleted' do
      message = create(:message)
      
      expect(message.deleted?).to be false
      message.soft_delete!
      expect(message.deleted?).to be true
      expect(message.content).to eq('')
    end
  end

  describe 'scopes' do
    it 'filters deleted messages with not_deleted scope' do
      message1 = create(:message)
      message2 = create(:message, :deleted)
      
      expect(Message.not_deleted).to include(message1)
      expect(Message.not_deleted).not_to include(message2)
    end
  end

  describe 'associations' do
    it 'belongs to room' do
      message = create(:message)
      expect(message.room).to be_a(Room)
    end

    it 'belongs to user' do
      message = create(:message)
      expect(message.user).to be_a(User)
    end
  end
end
