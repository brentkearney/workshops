# Copyright (c) 2016 Banff International Research Station.
# This file is part of Workshops. Workshops is licensed under
# the GNU Affero General Public License as published by the
# Free Software Foundation, version 3 of the License.
# See the COPYRIGHT file for details and exceptions.

module PersonDecorators
  extend ActiveSupport::Concern

  def name
    return '' if lastname.blank? || firstname.blank?
    firstname + ' ' + lastname
  end

  def lname
    return '' if lastname.blank? || firstname.blank?
    lastname + ', ' + firstname
  end

  def full_email
    %("#{name}" <#{email}>)
  end

  def dear_name
    if salutation.blank?
      if academic_status == 'Professor'
        'Prof. ' + lastname
      else
        name
      end
    else
      salutation + ' ' + lastname
    end
  end

  def him
    gender == 'M' ? 'him' : 'her'
  end

  def affil
    return '' if affiliation.nil?
    affil_with_department = String.new(affiliation) # new object necessary here
    affil_with_department << ", #{department}" unless department.blank?
    affil_with_department
  end

  def no_status
    academic_status.blank? || academic_status == 'Other'
  end

  def affil_with_title
    return '' if affiliation.blank?
    formatted_affil = affil
    if title.blank?
      formatted_affil << " — #{academic_status}" unless no_status
    else
      formatted_affil << " — #{title}"
    end
    formatted_affil.html_safe
  end

  def his_her
    gender == 'M' ? 'his' : 'her'
  end

  def uri
    uri = url
    unless uri.blank?
      uri = 'http://' + uri if uri !~ /^http/
    end
    uri
  end
end
