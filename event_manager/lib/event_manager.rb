# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(number)
  number = number.to_s
  number = number.gsub(' ', '')
  number = number.gsub('-', '')
  number = number.gsub('(', '')
  number = number.gsub(')', '')
  clean_number = ''
  clean_number = number if number.length == 10
  clean_number = number[1, -1] if number.chr == 1 && number.length == 11
  clean_number
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def best_hours(contents)
  hash = contents.reduce(Hash.new(0)) do |hash, row|
    #"11/23/08 20:44"
    #row_date = Date.strptime(row_arr[0], "%m/%d/%y")
    #p row_date
    row_arr = row[:regdate].split(" ")
    row_time = Time.strptime(row_arr[1], "%H:%M")
    hash[row_time.hour.to_s] += 1
    hash
  end
  max_hours = hash.values.max
  hash.select {|k, v| v == max_hours}
end

def best_weekday(contents)
  hash = contents.reduce(Hash.new(0)) do |hash, row|
    row_arr = row[:regdate].split(" ")
    row_date = Date.strptime(row_arr[0], "%m/%d/%y")
    hash[row_date.wday.to_s] += 1
    hash
  end
  max_day = hash.values.max
  hash.select {|k, v| v == max_day}
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter


#puts "The best hours are #{best_hours(contents).keys.join(', ')}"
puts "The best day is #{best_weekday(contents).keys.join(', ')}"


contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone = clean_phone_number(row[:homephone])
  puts row[:homephone]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  puts "Phone number: #{phone}"
  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end
