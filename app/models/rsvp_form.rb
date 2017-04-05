class RsvpForm < ComplexForms
  # validations for views/rsvp/index.html.erb
  attr_accessor :membership, :person, :event
  attr_reader :errors

  def initialize(invitation)
    @invitation = invitation
    @membership = invitation.membership
    @person = @membership.person
    @event = @membership.event
    @errors = ActiveModel::Errors.new(self)
  end

end
