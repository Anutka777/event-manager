# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  digits = phone_number.gsub(/\D/, '')
  if digits.length == 10 || (digits.length == 11 && digits[0] == '1')
    digits[1..10]
  else
    'invalid phone number'
  end
end

def clean_registration_hour(registration_hour)
  Time.strptime(registration_hour, '%m/%d/%y %k:%M').hour
end

def clean_registration_day(registration_day)
  day_of_week_id = Time.strptime(registration_day, '%m/%d/%y %k:%M').wday
  day_of_week_name = {
    0 => 'Sunday',
    1 => 'Monday',
    2 => 'Tuesday',
    3 => 'Wendnesday',
    4 => 'Thursday',
    5 => 'Friday',
    6 => 'Saturday'
  }
  day_of_week_name[day_of_week_id]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take_action'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def define_most_common_registration_hours(registration_hour_array)
  frequency_table = registration_hour_array.tally
  most_common_hours = []
  frequency_table.each { |hour, freq| most_common_hours.push(hour) if freq == frequency_table.values.max }
  puts "Most common registration hours are: #{most_common_hours.join(', ')}"
end

def define_most_common_registration_days(registration_day_array)
  frequency_table = registration_day_array.tally
  most_common_days = []
  frequency_table.each { |day, freq| most_common_days.push(day) if freq == frequency_table.values.max }
  puts "Most common registration days are: #{most_common_days.join(', ')}"
end

puts 'EventManager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

registration_hour_array = []
registration_day_array = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  registration_hour = clean_registration_hour(row[:regdate])
  registration_day = clean_registration_day(row[:regdate])

  registration_hour_array.push(registration_hour)
  registration_day_array.push(registration_day)
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end

define_most_common_registration_hours(registration_hour_array)
define_most_common_registration_days(registration_day_array)
