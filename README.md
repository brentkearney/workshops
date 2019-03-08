# Workshops

"Workshops" is software for managing scientific meetings, or small conferences. It is made with [Ruby on Rails](http://rubyonrails.org)
and released under the GPL-A open-source license. The software is intended to be used by institutions/organizations
who host workshops. It is used at the
[Banff International Research Station](https://workshops.birs.ca/events/future) for a limited number of functions: inviting (but not yet adding)
people to be participants in workshops, managing their online reply to invitations (RSVP), editing member records, rudimentary scheduling functions,
and simple workshop mailling lists.

Contributions to the project are most welcome. If you would like to add features yourself, please
[let me know](mailto:brentk@birs.ca), and/or submit a Pull Request. Or if you would like to pay for the development of additional features,
please [contact me](mailto:brent@netmojo.ca).


Installation instructions are below.

### Current Features
* **Sign-ins and sign-ups** for authorized event members, staff, and admin.
* **Fine-grained role-based access controls** allows different levels of access privileges for admin, staff, organizers, participants, and public.
* **Add Members** Staff and Organizers can add members to their workshops.
* **Event Invitations** Staff and Organizers can click a button to email a unique link to potential participants, inviting them to attend a workshop.
* **Multiple locations** for events. Each location has its own settings, email templates, forms, etc..
* **RSVPs** allows invited participants to reply to their invitation with "Yes", "No", "Maybe". Includes a text area to send a personal note to the organizer. If confirming, collects data for hotel reservations, etc., via a web form (unique per location) that is optimized for autofill. Automatically sends confirmation email to confirmed participants, using email templates based on workshop type.
* **[SparkPost](https://www.sparkpost.com) Integration** for improved email deliverability.
* **Workshop scheduling**: organizers can enter their workshop schedules, including talks with abstracts/descriptions, and choose when to publish their schedules to the public.
* **Default schedule templates** that staff can edit. Defaults get applied to all workshops' schedules which have not yet been edited.
* **LaTeX formatting** in all text editing areas, via [MathJax](https://www.mathjax.org), for mathematical formulae.
* **JSON output** of schedules and other event data, for easy display on external websites, [like this](http://www.birs.ca/events/2017/5-day-workshops/17w5030/schedule).
* **Authenticated JSON API** for [an external video recording system](http://www.birs.ca/facilities/automated-video) to update lecture records in the schedule, based on recordings made.
* **Email notifications** for staff and organizers when data changes, such as participant RSVPs and schedule updates during currently running workshops.
* **Event listing navigation** by user's events, future events, past events, events by location, and by year.
* **Event participant listings** grouped by attendance status (Confirmed, Invited, Declined, etc..), click for more detailed profile views of each participant.
* **Mail lists** each workshop automatically has mail lists (send one email that is automatically redistributed to a list of addresses) for groups of participants based on their attendance status. i.e. a mail list for confirmed participants, one for invited participants, one for declined participants...
* **Data imports** Workshop data is imported via calls to an external API, JSON.
* **Background jobs** to sync event membership data with external data source via API, and to send emails.
* **Settings in database** Application settings are stored in the database instead of config files, allowing staff and admins to easily change settings with web interface, on the fly.


### Upcoming Features:
* After-event feedback forms - automatically mail participants after an event, with one-click URL for providing feedback on the event.
* Drag & drop interface for scheduling features.
* Staff can assign hotel rooms, generate reports for hotel room bookings, and manage other hospitality details for workshop participants.
* Task scheduler, to allow automated performance of tasks such as reminder emails for participants to RSVP, after event feedback requests, etc.
* Staff and admin can create new events (currently they're imported via API).
* Admin users can manage other users (add/remove/change passwords, etc) - currently they can only change their own passwords.
* When organizers schedule a participant to give a talk, members optionally get notified with a link to fill in the talk title and abstract.
* Interface for managing Lectures, so participants can easily view all of the talks they've recorded, sign consent forms, add slides files, update abstracts.
* API integration with the Visual One room booking software, used by many hotels and conference centers, for automatic room booking.
* Addition of integrated forum software for each workshop, such as [Discourse](http://www.discourse.org), or possiblly Slack-alternative [Mattermost](https://mattermost.com).
* Crowd-sourcing feature for workshop participants to post open problems to the public, soliciting solutions.


## Installation Instructions:
The application is setup to work in a [Docker](http://www.docker.com) container.

1. Clone the repository: `git clone https://github.com/brentkearney/workshops.git`
2. Copy the example config files, and customize them to suit your needs. These include:
  ```
  ./docker-compose.yml.example
  ./Dockerfile.example
  ./entrypoint.sh.example
  ./nginx.conf.erb.example
  ./Passengerfile.json.example
  ```
  Bash command to copy them all to new names:
  ```
  for file in `ls -1 *.example`; do newfile=`echo $file | sed 's/\.example$//'`; cp $file $newfile; done
  ```
3. Edit the lib/tasks/ws.rake file to change default user account information, to set your own credentials for logging into the Workshops web interface. The default accounts are setup by the entrypoint.sh script running: `rake ws:create_admins RAILS_ENV=development`.
4. Edit docker-compose.yml to set your preferred usernames and passwords in the environment variables. Note the instructions
   at the top for creating data containers, for storing database and ruby gems persistently.

   The first time the database container is run, databases and database accounts will be created via the script at
   ./db/pg-init/init-user-db.sh. It uses the environment variables that you set in docker-compose.yml.
5. If you want your instance to be accessible at a domain, edit nginx.conf.erb to change `server_name YOUR.HOSTNAME.COM;`.
6. Run `docker-compose up` (or possibly `docker build .` first).
7. Login to the web interface (http://localhost) with the account you setup in ws.rake, and visit /settings (click the
  drop-down menu in the top-right and choose "Settings"). Update the Site settings with your preferences.

After the first time you run it, you will pobably want to *edit the entrypoint.sh script*, and comment out some of it, such as
creating the gemset, `rake db:seed`, adding default settings, and creating admin accounts. Change `bundle install` to `bundle update`.

The config files are setup to run Rails in development mode. If you would like to change it to production, edit the entrypoint.sh
to change all of the `RAILS_ENV=development` statements, and the Passengerfile.json `"environment": "development"` line.

It is currently configured to use [Sparkpost](https://www.sparkpost.com) for mail delivery, in production mode. If you're not using Sparkpost, edit the `config/environments/production.rb` file and adjust the [ActionMailer settings](https://guides.rubyonrails.org/v4.0.0/configuring.html#configuring-action-mailer) to your preference.


### License:
Workshops is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, version 3 of the License. See the [COPYRIGHT](COPYRIGHT)
file for details and exceptions.
