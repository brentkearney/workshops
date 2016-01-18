# Copyright (c) 2016 Brent Kearney. This file is part of Workshops.
# Workshops is licensed under the GNU Affero General Public License
# as published by the Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe "SchedulePolicy" do
  subject { SchedulePolicy }

  let (:normal_user) { FactoryGirl.build_stubbed :user }
  let (:staff_user) { FactoryGirl.build_stubbed :user, :staff }
  let (:admin_user) { FactoryGirl.build_stubbed :user, :admin }

  # TODO
  permissions :edit? do
  end
end
