# Workshops

"Workshops" is a niche application for managing scientific (or other) workshops. 
A _workshop_ is like a conference, only with less people, typically experts in a subject
domain who are sharing research with their peers.

**This application is in the early stages of development.**

I will set up a live demo site soon, and provide installation/deployment instructions
as well.

### Current Features
* Workshop data is imported via calls to an external API, and keeps data in sync with external data source.
* Role-based access control allowing different levels of privilege between admin, staff, organizers and participants.
* Staff and admin users can login. Workshop organizers can signup and login.
* Shows an index of all workshops.
* Shows workshop details: name, location, dates, description, etc..
* Shows workshop members, plus their details to varying degrees depending on user's privilege level.
* Staff & organizers can click a button to send email all to workshop participants.
* Staff can edit events if the staff user's location matches the event location.
* Staff can edit default workshop schedule templates.
* Organizers can easily edit and publish the schedules of their workshop(s).
* Default times for new schedule items are estimated based on previous schedule entries, to reduce data entry time.
* JSON API for [an external system](http://www.birs.ca/facilities/automated-video) to update lecture records.
* Public access to workshop schedules via JSON.

### Future Features:
* Organizers can add and invite members to their workshop.
* Invitations to members include a one-click RSVP link, setup profiles, etc..
* Staff can assign hotel rooms to workshop participants.
* Staff get email notifications when schedules of currently running workshops are updated.
* Admin users can manage (add/remove/change passwords, etc) other users.
* Staff can manage various email templates.
* Staff can send emails of various types to organizers and participants.
* Staff can schedule the automatic sending of emails. For example, send an RSVP reminder 3 months before the start of every workshop.
* When organizers schedule a participant to give a talk, members get notified with a link to fill in the talk title and abstract.
* Drag & drop interface to re-arrange schedule items.
* Interface for admin users to manage application settings.
* Addition of a forum/mail list software for each workshop. Considering embedding [Discourse](http://www.discourse.org), with an updated editor to support mathematics.
* Crowd-sourcing feature for workshop participants to post open problems to the public, soliciting solutions.

### License:
Workshops is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, version 3 of the License. See the [COPYRIGHT](COPYRIGHT)
file for details and exceptions.
