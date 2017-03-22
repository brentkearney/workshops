# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

RSpec.describe 'Model validations: Invitation', type: :model do
  before do
    @person = create(:person)
  end

  it 'has valid factory' do
    expect(create(:invitation, invited_by: @person.id)).to be_valid
  end

  it 'requires a membership' do
    i = build(:invitation, membership: nil)
    expect(i.valid?).to be_falsey
  end

  it 'requires invited_by' do
    i = build(:invitation, invited_by: nil)
    expect(i.valid?).to be_falsey
  end

  it 'requires a code' do
    i = build(:invitation, code: nil)
    expect(i.valid?).to be_falsey
  end

  it 'sets expires on save' do
    i = build(:invitation, invited_by: @person.id)
    expect(i.expires).to be_nil
    i.save
    expect(i.expires).not_to be_nil
  end
end
