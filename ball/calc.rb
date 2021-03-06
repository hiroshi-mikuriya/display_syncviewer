# frozen_string_literal: true

require 'json'

def average(ary)
  ary.inject(&:+) / [ary.size, 1].max
end

def median(ary)
  a = ary.clone.sort
  a.size.odd? ? a[a.size / 2] : a[a.size / 2 - 1, 2].inject(&:+) / 2
end

##
# @param [String] json_from_sync_viewer
# @return average of activities and amplitudes
def calc(json_from_sync_viewer)
  d = JSON.parse(json_from_sync_viewer, symbolize_names: true)
  activities = d[:data].values.map { |v| v[:activity] }
  amplitudes = d[:data].values.map do |v0|
    v0[:crosscorrelations].map { |v1| v1[:amplitude] }
  end
  amplitudes.flatten!.delete(0.0)
  # puts "activities : #{activities}"
  # puts "amplitudes : #{amplitudes}"
  [activities, amplitudes].map { |a| average(a) }
end

def activity_level(act)
	return 0 if act < 0.02 
	return 1 if act < 0.03
	return 2 if act < 0.04
  3
end

def amplitude_level(amp)
	return 0 if amp < 0.075
	return 1 if amp < 0.1
	return 2 if amp < 0.125
	return 3 if amp < 0.15
  4
end

##
# Debug
if $PROGRAM_NAME == __FILE__
  p calc %({
      "IDs": ["37c64106a9b65e66", "80124ad9e99d7a6c", "944f98bceafdf2e3"],
      "nodePhase": [157.6071, -295.3914, 107.2753],
      "data": {
        "37c64106a9b65e66": {
          "activity": 0.06605125037620148,
          "position": [1, 2],
          "sensorIndex": 0,
          "crosscorrelations": [
            {
              "amplitude": 7.7674,
              "followerID": "80124ad9e99d7a6c",
              "phase": 310,
              "value": -5.4456
            },
            {
              "amplitude": 1.234,
              "followerID": "944f98bceafdf2e3",
              "phase": 310,
              "value": -5.4456
            }
          ]
        },
        "80124ad9e99d7a6c": {
          "activity": 0.4,
          "position": [1, 2],
          "sensorIndex": 0,
          "crosscorrelations": [
            {
              "amplitude": 6.9324,
              "followerID": "944f98bceafdf2e3",
              "phase": 310,
              "value": -5.4456
            },
            {
              "amplitude": 1.5432,
              "followerID": "37c64106a9b65e66",
              "phase": 310,
              "value": -5.4456
            }
          ]
        },
        "944f98bceafdf2e3": {
          "activity": 0.9,
          "position": [1, 2],
          "sensorIndex": 0,
          "crosscorrelations": [
            {
              "amplitude": 6.9324,
              "followerID": "80124ad9e99d7a6c",
              "phase": 310,
              "value": -5.4456
            },
            {
              "amplitude": 1.5432,
              "followerID": "37c64106a9b65e66",
              "phase": 310,
              "value": -5.4456
            }
          ]
        }
      },
      "time": 1521701589020
    }
  )
end
