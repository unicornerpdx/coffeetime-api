module Timezone

  def self.offset_to_zone(offset)
    timezones = [
      'America/Los_Angeles',
      'America/Denver',
      'America/Chicago',
      'America/New_York',
      'America/Phoenix',
      'Europe/London',
      'Europe/Berlin',
      'Europe/Helsinki',
      'Europe/Moscow',
      'Asia/Singapore',
      'Asia/Tokyo',
      'Pacific/Midway',
      'Pacific/Honolulu',
      'America/Juneau',
      'Asia/Tehran',
      'Asia/Baku',
      'Asia/Kabul',
      'Asia/Karachi',
      'Asia/Kolkata',
      'Australia/Darwin',
      'Pacific/Guam',
      'Australia/Adelaide',
      'Australia/Melbourne',
      'Pacific/Fiji',
      'Pacific/Auckland'
    ]

    zone = nil

    timezones.each do |tz_name|
      timezone = Timezone::Zone.new :zone => tz_name
      if zone.nil? and timezone.utc_offset == offset
        zone = tz_name
      end
    end

    zone
  end

end