# ./app/services/rsvp_deadline.rb
#
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

# Calculates RSVP deadline for invitation emails
class RsvpDeadline
  def initialize(start_date, sent_on = DateTime.current)
    @start_date = start_date.to_time
    @sent_on = sent_on.to_time
  end

  def rsvp_by
    rsvp_deadline = (@sent_on + 4.weeks).strftime('%B %-d, %Y')
    if (@start_date - @sent_on).to_i < 10.days.to_i
      rsvp_deadline = @start_date.prev_week(:tuesday).strftime('%B %-d, %Y')
    elsif (@start_date - @sent_on).to_i < 2.month.to_i
      rsvp_deadline = (@sent_on + 10.days).strftime('%B %-d, %Y')
    elsif (@start_date - @sent_on).to_i < (3.months + 5.days).to_i
      rsvp_deadline = (@sent_on + 21.days).strftime('%B %-d, %Y')
    end
    rsvp_deadline
  end
end
