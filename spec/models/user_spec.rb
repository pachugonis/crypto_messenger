require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { is_expected.to be_valid }

    it 'requires email_address' do
      subject.email_address = nil
      expect(subject).not_to be_valid
    end

    it 'requires username' do
      subject.username = nil
      expect(subject).not_to be_valid
    end

    it 'requires unique email_address' do
      create(:user, email_address: 'test@example.com')
      subject.email_address = 'test@example.com'
      expect(subject).not_to be_valid
    end

    it 'requires unique username' do
      create(:user, username: 'testuser')
      subject.username = 'testuser'
      expect(subject).not_to be_valid
    end

    it 'requires password minimum length' do
      subject.password = '12345'
      expect(subject).not_to be_valid
    end
  end

  describe 'roles' do
    it 'defaults to user role' do
      user = create(:user)
      expect(user.user?).to be true
    end

    it 'can be admin' do
      user = create(:user, :admin)
      expect(user.admin?).to be true
    end
  end

  describe 'locking' do
    let(:user) { create(:user) }

    it 'can be locked' do
      expect(user.locked?).to be false
      user.lock!
      expect(user.locked?).to be true
    end

    it 'can be unlocked' do
      user.lock!
      user.unlock!
      expect(user.locked?).to be false
    end
  end

  describe 'associations' do
    it 'has many rooms through room_participants' do
      user = create(:user)
      room = create(:room)
      create(:room_participant, user: user, room: room)
      
      expect(user.rooms).to include(room)
    end
  end
end
