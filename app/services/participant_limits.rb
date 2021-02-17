
module ParticipantLimits
  def max_participants_exceeded?(extras = 0)
    msg = ''
    msg = max_hybrid_msg(extras) if @event.hybrid?

    msg = "You may not invite more than #{max_participants}
      participants.".squish if !@event.hybrid? && max_participants?(extras)

    msg << " You may not invite more than #{@event.max_observers}
      observers.".squish if max_observers?(extras)

    msg
  end

  def max_hybrid_msg(extras = 0)
    msg = ''
    invited_physical = @memberships.count do |m|
        m.attendance == 'Not Yet Invited' && m.role == 'Participant'
    end
    participant_total = @event.num_invited_in_person + invited_physical + extras
    if participant_total > @event.max_participants
      msg = "You may not invite more than #{@event.max_participants}
                    in-person participants.".squish
    end

    invited_virtual = @memberships.count do |m|
      m.attendance == 'Not Yet Invited' && m.role == 'Virtual Participant'
    end

    if @event.num_invited_virtual + invited_virtual + extras > @event.max_virtual
      msg << " You may not invite more than #{@event.max_virtual} virtual
            participants.".squish
    end
    msg
  end

  def max_participants
    @event.online? ? @event.max_virtual : @event.max_participants
  end

  def max_participants?(extras = 0)
    uninvited = @memberships.count { |m| m.attendance == 'Not Yet Invited' &&
      m.role != 'Observer' }

    @event.num_invited_participants + uninvited + extras > max_participants
  end

  def max_observers?(extras = 0)
    uninvited_observers = @memberships.count { |m| m.role == 'Observer' &&
      m.attendance == 'Not Yet Invited' }
    return false if uninvited_observers == 0
    total_observers = @event.num_invited_observers + uninvited_observers + extras
    total_observers > @event.max_observers
  end
end
