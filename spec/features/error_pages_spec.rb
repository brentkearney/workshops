# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Custom error pages', type: :feature do

  it 'displays a 404 error message' do
    visit '/404'
    expect(page.body).to have_text('Error 404: Page Not Found')
  end

  it 'displays a 500 error message, and help email' do
    visit '/500'
    expect(page.body).to have_text('Error 500: Internal Server Error')
    expect(page.body).to include(Global.email.webmaster)
  end

end