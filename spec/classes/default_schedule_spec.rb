# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

require 'rails_helper'

# DefaultSchedule creates a default schedule template for events that have none
describe 'DefaultSchedule' do
  before(:all) do
    @event = FactoryGirl.create(:event)
    authenticate_user # sets @user & @person
    @user.member!
    @membership = FactoryGirl.create(:membership, event: @event, person: @person, role: 'Organizer')
  end

  after do
    Lecture.delete_all
    Schedule.delete_all
  end

  it 'accepts event and user objects as a parameter' do
    DS = DefaultSchedule.new(@event, @user)
    expect(DS.class).to eq(DefaultSchedule)
  end

  context 'If there is NO Template Schedule in the database' do
    before(:all) do
      Event.where(:template => true).each do |template_event|
        template_event.destroy!
      end
      membership = @event.memberships.first
      expect(membership.role).to eq('Organizer')
    end

    it 'does not add any items to the event\'s schedule' do
      schedules = DefaultSchedule.new(@event, @user).schedules
      expect(schedules).to be_empty
    end
  end

  context 'If there is a Template Schedule in the database' do
    before(:all) do
      @tevent = FactoryGirl.create(:event,
                                   code: '15w0001',
                                   name: 'Testing Schedule Template event',
                                   event_type: @event.event_type,
                                   start_date: '2015-01-04',
                                   end_date: '2015-01-09',
                                   template: true
      )
      expect(@tevent.template).to be_truthy

      expect(@tevent.schedules).to be_empty
      9.upto(12) do |t|
        FactoryGirl.create(:schedule,
                           event: @tevent,
                           name: "Item at #{t}",
                           start_time: (@tevent.start_date + 2.days).to_time.change({ hour: t }),
                           end_time: (@tevent.start_date + 2.days).to_time.change({ hour: t+1 })
        )
      end
      expect(@tevent.schedules).not_to be_empty
    end

    context 'And the user IS an organizer of the event' do
      before(:all) do
        membership = @event.memberships.first
        expect(membership.role).to eq('Organizer')
      end

      context 'If the event has at least one schedule item' do
        before(:all) do
          item = FactoryGirl.build(:schedule, name: 'This one item', event_id: @event.id,
                                   start_time: (@event.start_date + 2.days).to_time.change({ hour: 9 }),
                                   end_time: (@event.start_date + 2.days).to_time.change({ hour: 10 })
          )
          @event.schedules.create(item.attributes)
        end

        it 'does not add any items to the event\'s schedule' do
          expect(@event.schedules.size).to eq(1)
          expect(DefaultSchedule.new(@event, @user).schedules.size).to eq(1)
        end
      end

      context 'If the event has no previously associated schedule items' do
        before(:each) do
          @event.schedules.delete_all
          expect(@tevent.schedules).not_to be_empty
        end

        it 'copies schedule items from the template event' do
          expect(@event.schedules).to be_empty
          expect(@tevent.schedules).not_to be_empty

          ds = DefaultSchedule.new(@event, @user)
          expect(@event.schedules).not_to be_empty
        end

        it 'changes the dates of the template event schedules to match the given event' do
          expect(@event.schedules).to be_empty
          expect(@tevent.schedules).not_to be_empty
          ds = DefaultSchedule.new(@event, @user)

          @tevent.schedules.each do |t_item|
            e_item = @event.schedules.select {|i| i.name == t_item.name }.first
            expect(e_item.start_time.hour).to eq(t_item.start_time.hour)
            expect(e_item.start_time.min).to eq(t_item.start_time.min)
            expect(e_item.end_time.hour).to eq(t_item.end_time.hour)
            expect(e_item.end_time.min).to eq(t_item.end_time.min)
          end
        end
      end
    end

    context 'And the user is NOT an organizer of the event' do
      before(:all) do
        membership = @event.memberships.first
        expect(membership.role).to eq('Organizer')
        membership.role = 'Participant'
        membership.save!
      end

      it 'does not copy template schedule items' do
        @event.schedules.delete_all
        expect(@event.memberships.first.role).to eq('Participant')
        expect(@event.schedules).to be_empty
        expect(@tevent.schedules).not_to be_empty

        ds = DefaultSchedule.new(@event, @user)
        expect(@event.schedules).to be_empty
      end
    end
  end

end
