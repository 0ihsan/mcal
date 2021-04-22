//
//  main.swift
//  mcal
//
//  Created by ihsan on 2021-4-22...
//

import Foundation
import EventKit

let USAGE = """
\u{001B}[33mUSAGE\u{001B}[0m
	mcal <calendar_name> <time> <event title> at <location>
	mcal end
	mcal continue

\u{001B}[33mEXAMPLES\u{001B}[0m
	mcal personal 30 eat & surf web
	mcal business 60 develop calendar cli
	mcal spare 15 break
	mcal business 180 fix price update
	mcal spare 30 play chess at lichess.com
"""

var time: Double = 60   // mins

let arguments = CommandLine.arguments
var cmd = ""
if arguments.count > 1 { cmd = arguments[1] }
switch cmd {
case "end", "e":
	print("ending ", terminator:"")
case "continue", "c", "con":
	print("continuing ", terminator:"")
	if arguments.count > 2 {time = Double(arguments[2])!}
	print(time, "mins")
case "next", "start", "n", "s":
	print("starting next event: ", terminator:"")
default:
	break
}

var store = EKEventStore()
let calendars = store.calendars(for: .event)
let midnight = Calendar.current.startOfDay(for: Date())
let next_midnight = Calendar.current.date(
	byAdding: .day, value: 1, to: midnight)!
let predicate_events_since_midnight = store.predicateForEvents(
	withStart: midnight, end: Date(), calendars: calendars)
let predicate_events_until_next_midnight = store.predicateForEvents(
	withStart: Date(), end: next_midnight, calendars: calendars)
let events_since_midnight = store.events(matching: predicate_events_since_midnight)
let events_until_next_midnight = store.events(matching: predicate_events_until_next_midnight)
let current_event = events_since_midnight.last!
let previous_event = events_since_midnight[events_since_midnight.count - 2]
let next_event = events_until_next_midnight[0]


switch cmd {

case "end", "e":
	current_event.endDate = Date()
	try store.save(current_event, span: .thisEvent, commit: true)
	print(current_event.title!)

case "next", "start", "n", "s":
	next_event.startDate = Date()
	next_event.endDate = Date(timeIntervalSinceNow: time * 60)
	try store.save(next_event, span: .thisEvent, commit: true)
	print(next_event.title!)


case "continue", "con", "c":
	current_event.endDate = Date()
	let prev_event_copied = EKEvent.init(eventStore: store)
	prev_event_copied.calendar = previous_event.calendar
	prev_event_copied.title = previous_event.title
	prev_event_copied.startDate = Date()
	prev_event_copied.endDate = Date(timeIntervalSinceNow: time * 60)
	try store.save(current_event, span: .thisEvent, commit: true)
	try store.save(prev_event_copied, span: .thisEvent, commit: true)
	print(previous_event.title!)

default:
	// end current event
	current_event.endDate = Date()
	try store.save(current_event, span: .thisEvent, commit: true)
	
	// add new event
	var calendar_not_found = true
	for cal in calendars {
		if (cal.title.lowercased().contains(arguments[1])) {
			calendar_not_found = false
			let new_event = EKEvent.init(eventStore: store)
			new_event.calendar = cal

			var cal_time_and_title = arguments
			if (arguments.contains("at")) {
				let args_splitted = arguments.split(separator: "at")
				cal_time_and_title = Array(args_splitted[0])
				let after_at = args_splitted[1]
				if (after_at.count > 0) {
					new_event.location = after_at.joined(separator: " ")
				}
			}
			
			if cal_time_and_title.count > 3 {
				new_event.title = cal_time_and_title.dropFirst(3).joined(separator: " ")
			} else if (cal_time_and_title.count == 3) {
				new_event.title = cal_time_and_title.dropFirst(2).joined(separator: " ")
			} else {
				print(USAGE)
				exit(1)
			}

			new_event.startDate = Date()
			new_event.endDate = Date(timeIntervalSinceNow: time * 60)
			try store.save(new_event, span: .thisEvent, commit: true)
			print("ends at: ", Date.init(timeIntervalSinceNow: time * 60))
			break
		}
	}
	if (calendar_not_found) {
		print("no such calendar:", "spare")
	}


}

// create dates
//formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"

//let sources = store.sources
//for source in sources {
//	print(source.title)
//	for calendar in source.calendars(for: .event) {
//		print(calendar.title)
//	}
//}
