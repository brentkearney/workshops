# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe User, type: :model do
  it 'has valid factory' do
    user = FactoryGirl.create(:user)
    #puts "User name: #{user.name}, email: #{user.email}"
    expect(user).to be_valid
  end

  it 'requires an email address' do
    u = FactoryGirl.build(:user, email: '')
    expect(u.valid?).to be_falsey

    u.email = 'foo@bar.com'
    expect(u.valid?).to be_truthy
  end

  it 'requires a valid email address' do
    u = FactoryGirl.build(:user, email: 'bleh')
    expect(u.valid?).to be_falsey

    u.email = 'bleh@blah.edu'
    expect(u.valid?).to be_truthy
  end

  it 'requires a password' do
    u = FactoryGirl.build(:user, password: '')
    expect(u.valid?).to be_falsey
  end

  it 'requires a person association' do
    u = FactoryGirl.build(:user, person_id: '')
    expect(u.valid?).to be_falsey
  end

  it 'the person association works' do
    u = FactoryGirl.create(:user)
    expect(u.person.name).not_to be_nil
    expect(u.person.name).to match(/\w/)
  end
  
  it 'has a role' do
    u = FactoryGirl.create(:user)
    expect(u.role).to eq('member')
  end

  it 'sets a default role to member, if none assigned' do
    u = FactoryGirl.build(:user)
    user = User.create(u.attributes.delete(:role))
    expect(user.role).to eq('member')
  end

  it 'has a location' do
    u = FactoryGirl.create(:user)
    expect(u.location).to eq('BIRS')
  end

  it 'if role is staff, requires location' do
    u = FactoryGirl.build(:user, role: 'staff', location: '')
    expect(u).not_to be_valid

    u.location = 'FOO'
    expect(u).to be_valid
  end

  it 'if role is not staff, does not require a location' do
    u = FactoryGirl.build(:user, location: '')
    expect(u.role).not_to eq('staff')
    expect(u).to be_valid
  end


end
