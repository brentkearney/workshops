# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

describe 'Editing a Schedule Item', type: :feature do
  before do
    authenticate_user
    @event = create(:event_with_schedule)
  end

  after(:each) do
    Warden.test_reset!
  end

  context 'As an admin user:' do
    before do
      @user.admin!
    end

    it 'has all of the editable fields for a schedule item' do
      item = @event.schedules.first
      visit event_schedule_edit_path(@event, item)

      event_days = @event.days.map {|day| day.strftime("%A, %B %e") }
      expect(page.has_select?('schedule[day]', with_options: event_days))
      expect(page.has_select?('Start time2'))
      expect(page).to have_field('schedule_start_time_4i')
      expect(page).to have_field('schedule_end_time_4i')
      expect(page.has_field?('Title', with: item.name))
      expect(page.has_field?('schedule_description', with: item.description))
      expect(page.has_field?('Location', with: item.location))
      expect(page).to have_field('schedule_staff_item', checked: false)
    end

    it 'clicking an item from the schedule index opens it in the edit form' do
      visit event_schedule_index_path(@event)
      item = @event.schedules.first
      click_link item.name
      expect(current_path).to eq(event_schedule_edit_path(@event, item))
    end

    it 'clicking an item from edit form sidebar opens it in the edit form' do
      item = @event.schedules.first
      visit event_schedule_edit_path(@event, item)

      sidebar_item = @event.schedules.select { |i| i.start_time.hour == 11 }
                           .first
      click_link sidebar_item.name
      expect(current_path).to eq(event_schedule_edit_path(@event, sidebar_item))
    end

    it 'editing an item to overlap with another item (in a different room)
      produces a warning notice' do
      first_item = @event.schedules.first
      new_start = first_item.start_time - 5.minutes
      new_stop = first_item.start_time + 5.minutes
      last_item = @event.schedules.last

      visit event_schedule_edit_path(@event, last_item)
      page.select new_start.strftime('%H'), from: 'schedule_start_time_4i'
      page.select new_start.strftime('%M'), from: 'schedule_start_time_5i'
      page.select new_stop.strftime('%H'), from: 'schedule_end_time_4i'
      page.select new_stop.strftime('%M'), from: 'schedule_end_time_5i'
      page.fill_in 'schedule_location', with: 'Elsewhere'

      click_button 'Update Schedule'
      expect(find('div.alert-warning').text)
        .to match(/^Warning:\n#{last_item.name}.+overlaps with.+\n.#{first_item.name}.+/)
    end

    it 'staff items have time limit selectors' do
      first_item = @event.schedules.first
      first_item.staff_item = true
      first_item.save

      visit event_schedule_edit_path(@event, first_item)

      expect(page).to have_field('schedule_earliest_4i')
      expect(page).to have_field('schedule_latest_4i')
    end

    context 'For a schedule (non-lecture) item' do
      before :each do
        @item = @event.schedules.first
        visit event_schedule_edit_path(@event, @item)
      end

      it 'updates the day of the item to the selected day' do
        new_day = @item.start_time.to_date + 2.days
        page.select new_day.strftime('%A'), from: 'schedule_day'
        click_button 'Update Schedule'
        expect(Schedule.find(@item.id).start_time.to_date).to eq(new_day)
      end

      it 'it updates the month of the item if the new day is in a different
        month' do
        start_date = '2015-08-30'.to_date
        end_date = start_date + 5.days
        new_event = create(:event, start_date: start_date, end_date: end_date)

        new_item = create(:schedule,
                          event: new_event,
                          name: 'Item at the end of the month',
                          start_time: (new_event.start_date + 1.day).to_time
                                                .change(hour: 9),
                          end_time: (new_event.start_date + 1.day).to_time
                                              .change(hour: 10))
        visit event_schedule_edit_path(new_event, new_item)
        new_day = new_item.start_time.to_date + 3.days
        page.select new_day.strftime('%A'), from: 'schedule_day'
        click_button 'Update Schedule'
        expect(Schedule.find(new_item.id).start_time.month)
          .to eq(new_event.end_date.month)
      end

      it 'updates the start time and end times to the selected times' do
        new_start = @item.start_time + 6.hours
        new_end = new_start + 1.hours
        page.select new_start.strftime('%H'), from: 'schedule_start_time_4i'
        page.select new_end.strftime('%H'), from: 'schedule_end_time_4i'
        click_button 'Update Schedule'
        expect(Schedule.find(@item.id).start_time).to eq(new_start)
        expect(Schedule.find(@item.id).end_time).to eq(new_end)
      end

      it 'updates the name of the item' do
        page.fill_in 'schedule_name', with: 'Better name than nth item'
        click_button 'Update Schedule'
        expect(Schedule.find(@item.id).name)
          .to eq('Better name than nth item')
      end

      it 'updates the description of the item' do
        page.fill_in 'schedule_description', with: 'Here is a new description'
        click_button 'Update Schedule'
        expect(Schedule.find(@item.id).description)
          .to eq('Here is a new description')
      end

      it 'updates the location of the item' do
        page.fill_in 'schedule_location', with: 'In the woods'
        click_button 'Update Schedule'
        expect(Schedule.find(@item.id).location).to eq('In the woods')
      end

      context 'If the "change_similar" option is selected on update' do
        before do
          @item2 = create(:schedule, event: @event, name: @item.name,
                                     start_time: (@item.start_time + 1.days),
                                     end_time: (@item.end_time + 1.days))
          @item3 = create(:schedule, event: @event, name: @item.name,
                                     start_time: (@item.start_time + 2.days),
                                     end_time: (@item.end_time + 2.days))
          visit event_schedule_edit_path(@event, @item)
        end

        it 'updates the times of similar items' do
          new_start = @item.start_time + 5.hours
          new_end = new_start + 1.hours

          page.select new_start.strftime('%H'), from: 'schedule_start_time_4i'
          page.select new_end.strftime('%H'), from: 'schedule_end_time_4i'
          page.check('change_similar')
          click_button 'Update Schedule'

          expect(Schedule.find(@item.id).start_time.hour).to eq(new_start.hour)
          expect(Schedule.find(@item2.id).start_time.hour).to eq(new_start.hour)
          expect(Schedule.find(@item3.id).start_time.hour).to eq(new_start.hour)
        end

        it 'updates the names of similar items' do
          new_item_name = 'A different name than before'
          page.fill_in 'schedule_name', with: new_item_name
          page.check('change_similar')
          click_button 'Update Schedule'
          expect(Schedule.find(@item.id).name).to eq(new_item_name)
          expect(Schedule.find(@item2.id).name).to eq(new_item_name)
          expect(Schedule.find(@item3.id).name).to eq(new_item_name)
        end

        it 'updates the descriptions of similar items' do
          newer_description = 'New and improved description!'
          page.fill_in 'schedule_description', with: newer_description
          page.check('change_similar')
          click_button 'Update Schedule'
          expect(Schedule.find(@item.id).description).to eq(newer_description)
          expect(Schedule.find(@item2.id).description).to eq(newer_description)
          expect(Schedule.find(@item3.id).description).to eq(newer_description)
        end

        it 'updates the locations of similar items' do
          new_location = 'A better spot for this'
          page.fill_in 'schedule_location', with: new_location
          page.check('change_similar')
          click_button 'Update Schedule'
          expect(Schedule.find(@item.id).location).to eq(new_location)
          expect(Schedule.find(@item2.id).location).to eq(new_location)
          expect(Schedule.find(@item3.id).location).to eq(new_location)
        end
      end
    end
  end

  context 'As non-admin users: ' do
    before do
      @user.member!
      @membership = create(:membership, event: @event, person: @person,
                                        attendance: 'Confirmed',
                                        role: 'Participant')
      @item = @event.schedules.last
    end

    def no_add_item_button
      visit event_schedule_index_path(@event)
      expect(page.body).to have_text(@item.name)
      expect(page.body).not_to have_link('Add an item')
    end

    def has_add_item_button
      visit event_schedule_index_path(@event)
      expect(page.body).to have_text(@item.name)
      expect(page.body).to have_link('Add an item')
    end

    def disallows_editing
      visit event_schedule_edit_path(@event, @item)
      expect(page).to have_css('div.alert.alert-error')
      expect(page.body).to have_text('Only staff and event organizers may modify
        the schedule'.squish)
    end

    def allows_editing
      visit event_schedule_edit_path(@event, @item)
      expect(page).not_to have_css('div.alert.alert-error')
      expect(current_path).to eq(event_schedule_edit_path(@event, @item))
      fill_in :schedule_name, with: 'New name'
      click_button 'Update Schedule'
      expect(page.body).to have_css('div.alert.alert-notice')
      expect(page.body).to have_text('successfully updated')
    end

    context 'For Participants (non-organizers, non-staff)' do
      context 'unpublished schedule' do
        it 'does not show the schedule' do
          expect(@event.publish_schedule).to be_falsey
          expect(page.body).not_to have_text(@item.name)
        end
      end

      context 'published schedule' do
        before do
          @event.publish_schedule = true
          @event.save
        end

        it 'shows the schedule' do
          visit event_schedule_index_path(@event)
          expect(page.body).to have_text(@item.name)
        end

        it 'does not show the "Add Item" buttons on the schedule' do
          no_add_item_button
        end

        it 'does not allow editing of schedule items' do
          disallows_editing
        end
      end
    end

    context 'For Staff who DO NOT have the same location as the event' do
      before do
        @user.staff!
        @user.location = 'Elsewhere'
        @user.save!
      end

      context 'unpublished schedule' do
        it 'does not show the schedule' do
          @event.publish_schedule = false
          @event.save

          visit event_schedule_index_path(@event)

          expect(page.body).not_to have_text(@item.name)
        end

        it 'does not allow editing of schedule items' do
          disallows_editing
        end
      end

      context 'published schedule' do
        before do
          @event.publish_schedule = true
          @event.save
        end

        it 'shows the schedule' do
          visit event_schedule_index_path(@event)

          expect(page.body).to have_text(@item.name)
        end

        it 'does not show the "Add Item" buttons on the schedule' do
          no_add_item_button
        end

        it 'does not allow editing of schedule items' do
          disallows_editing
        end
      end
    end

    context 'For Staff who have the same location as the event, it' do
      before do
        @user.staff!
        @user.location = @event.location
        @user.save!
      end

      context 'unpublished schedule' do
        before do
          @event.publish_schedule = false
          @event.save
        end

        it 'shows the schedule' do
          visit event_schedule_index_path(@event)

          expect(page.body).to have_text(@item.name)
        end

        it 'shows the "Add Item" buttons on the schedule' do
          has_add_item_button
        end

        it 'allows editing of schedule items' do
          allows_editing
        end

        it 'has a "staff item" checkbox' do
          visit event_schedule_edit_path(@event, @item)
          expect(page.body).to have_css('input#schedule_staff_item')
        end

        it 'staff items have time limit selectors' do
          @item.staff_item = true
          @item.save

          visit event_schedule_edit_path(@event, @item)

          expect(page).to have_field('schedule_earliest_4i')
          expect(page).to have_field('schedule_latest_4i')
        end
      end
    end

    context 'For Organizers of the Event' do
      before do
        @user.member!
        @membership.role = 'Organizer'
        @membership.save!
      end

      context 'unpublished schedule' do
        before do
          @event.publish_schedule = false
          @event.save
        end

        it 'shows the schedule' do
          visit event_schedule_index_path(@event)

          expect(page.body).to have_text(@item.name)
        end

        it 'shows the "Add Item" buttons on the schedule' do
          has_add_item_button
        end

        it 'allows editing of schedule items' do
          allows_editing
        end

        it 'has no "staff item" checkbox' do
          visit event_schedule_edit_path(@event, @item)
          expect(page.body).not_to have_css('input#schedule_staff_item')
        end
      end

      context 'staff notifications' do
        it 'notifies staff of changes to current event schedules' do
          ActionMailer::Base.deliveries.clear
          allow_any_instance_of(Schedule).to receive(:notify_staff?)
            .and_return(true)

          original_name = @item.name
          visit event_schedule_edit_path(@event, @item)
          fill_in :schedule_name, with: 'Current event: new name'
          click_button 'Update Schedule'

          expect(page.body).to have_text('successfully updated')
          expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).not_to eq 0
          message = ActiveJob::Base.queue_adapter.enqueued_jobs.last[:args].last
          expect(message).to have_text(original_name)
          expect(message).to have_text('Current event: new name')
          expect(message).to have_text("Updated by: #{@user.person.name}")
        end
      end

      context 'editing staff items' do
        before do
          @item.staff_item = true
          @item.save
        end

        it 'does not show time limit selectors' do
          visit event_schedule_edit_path(@event, @item)

          expect(page).not_to have_field('schedule_earliest_4i')
          expect(page).not_to have_field('schedule_latest_4i')
        end

        # it 'disables times outside of time limits' do
        #   @item.earliest = @item.start_time - 1.hour
        #   @item.latest = @item.start_time + 1.hour
        #   @item.save

        #   visit event_schedule_edit_path(@event, @item)

        #   eselect = find(:select, 'schedule_start_time_4i')
        #   expect(eselect).to have_selector(:option,
        #                                    @item.earliest.strftime('%H'),
        #                                    disabled: true)
        #   lselect = find(:select, 'schedule_end_time_4i')
        #   expect(lselect).to have_selector(:option,
        #                                    @item.latest.strftime('%H'),
        #                                    disabled: true)
        #   # note: minutes must be disabled via javascript
        # end

        context 'within schedule lock time' do
          before do
            lc = @event.location
            lead_time = Setting.Locations[lc]['lock_staff_schedule'].to_duration
            @event.start_date = Date.current + lead_time - 1.day
            @event.end_date = @event.start_date + 5.days
            @event.save
          end

          it 'does not allow editing' do
            visit event_schedule_edit_path(@event, @item)
            expect(page).not_to have_button('Update Schedule')
          end

          it 'shows an explanatory message' do
            visit event_schedule_edit_path(@event, @item)
            expect(page).to have_css('p#staff_item_locked')
          end

          it 'offers contact info for changing the item' do
            visit event_schedule_edit_path(@event, @item)
            station_manager = Setting.Emails[@event.location]['station_manager']
            expect(page).to have_link('Request Change')
            expect(page.body).to include("mailto:#{station_manager}")
          end

          it 'has no delete button' do
            visit event_schedule_edit_path(@event, @item)
            expect(page).not_to have_link('Delete Schedule Item')
          end
        end
      end
    end

    context 'For Organizers of other events' do
      before do
        @user.member!
        @membership.delete
        new_event = create(:event)
        create(:membership, event: new_event, person: @person,
                            attendance: 'Confirmed',
                            role: 'Organizer')
        create(:schedule,
               event: new_event,
               name: 'Item at 9',
               start_time: (new_event.start_date + 2.days).to_time
                .change(hour: 9),
               end_time: (new_event.start_date + 2.days).to_time
                .change(hour: 10))
      end

      context 'unpublished schedule' do
        before do
          @event.publish_schedule = false
          @event.save
        end

        it 'does not show the schedule' do
          visit event_schedule_index_path(@event)
          expect(page.body).not_to have_text(@item.name)
        end
      end

      context 'published schedule' do
        before do
          @event.publish_schedule = true
          @event.save
        end

        it 'shows the schedule' do
          visit event_schedule_index_path(@event)

          expect(page.body).to have_text(@item.name)
        end

        it 'does not show the "Add Item" buttons on the schedule' do
          no_add_item_button
        end

        it 'does not allow editing of schedule items' do
          disallows_editing
        end
      end
    end
  end
end
