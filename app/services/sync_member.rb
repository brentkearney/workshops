# app/services/sync_member.rb
# Copyright (c) 2018 Banff International Research Station
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# updates one membership + person record with data from remote db
class SyncMember
  attr_reader :membership
  include Syncable

  def initialize(membership)
    @membership = membership
    sync_member
  end

  def sync_member
    return if membership.person.legacy_id.blank?
    lc = LegacyConnector.new
    remote_member = lc.get_member(membership)
    return if remote_member.blank?
    return if remote_member['Membership']['updated_at'].blank?
    return if membership.updated_at.to_i >=
              remote_member['Membership']['updated_at'].to_i

    remote_member = fix_remote_fields(remote_member)
    updated_person = update_record(membership.person, remote_member['Person'])
    updated_membership = update_record(membership, remote_member['Membership'])
    updated_membership.person = updated_person
    save_membership(updated_membership)
  end
end
