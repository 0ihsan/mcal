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
	mcal <end | e>
	mcal <continue | con | c>
	mcal <next | start | n | s>
	mcal <calendar_name> <time_mins> <event title> [ at <location> ]

\u{001B}[33mEXAMPLES\u{001B}[0m
	mcal personal 30 eat & surf web
	mcal business 60 develop calendar cli
	mcal spare 15 break
	mcal business 120 improve mcal at https://github.com/ihsanturk/mcal
	mcal spare 30 play chess at https://lichess.com
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
case "next", "start", "n", "s":
	print("starting next event: ", terminator:"")
case "help","h","-h","--help":
	print(USAGE)
	exit(0)
default:
	if arguments.count > 2 {time = Double(arguments[2])!}
}

var store = EKEventStore()
let calendars = store.calendars(for: .event)
let midnight = Calendar.current.startOfDay(for: Date())
let next_midnight = Calendar.current.date(
	byAdding: .day, value: 1, to: midnight)!
let predicate_event_current = store.predicateForEvents(
	withStart: Date(), end: Date(), calendars: calendars)
let predicate_events_since_midnight = store.predicateForEvents(
	withStart: midnight, end: Date(), calendars: calendars)
let predicate_events_until_next_midnight = store.predicateForEvents(
	withStart: Date(), end: next_midnight, calendars: calendars)
let events_current = store.events(matching: predicate_event_current)
let events_since_midnight = store.events(matching: predicate_events_since_midnight)
let events_until_next_midnight = store.events(matching:
	predicate_events_until_next_midnight)
	.filter {
		 event in return !event.isAllDay
	}

var current_event: EKEvent?
var last_event: EKEvent?
var previous_event: EKEvent?

if events_current.count > 0 {
	current_event = events_current.last
}
if events_since_midnight.count > 0 {
	last_event = events_since_midnight.last
}
if events_since_midnight.count > 1 {
	previous_event = events_since_midnight[events_since_midnight.count - 2]
}

switch cmd {

case "end", "e":
	if last_event != nil {
		last_event!.endDate = Date()
		try store.save(last_event!, span: .thisEvent, commit: true)
		if last_event!.title != nil {
			print(last_event!.title!)
		}
	} else {
		print("no event found since", midnight)
	}

case "next", "start", "n", "s":
	var next_event_index = 0
	if current_event != nil {
		current_event!.endDate = Date()
		try store.save(current_event!, span: .thisEvent, commit: true)
		next_event_index += 1
	}
	if (events_until_next_midnight.count > 0) {
		let next_event = events_until_next_midnight[next_event_index]
		next_event.startDate = Date()
		next_event.endDate = Date(timeIntervalSinceNow: time * 60)
		try store.save(next_event, span: .thisEvent, commit: true)
		print(next_event.title!)
	} else {
		print("no event found until", next_midnight)
	}


case "continue", "con", "c":
	if last_event != nil && previous_event != nil {
		last_event!.endDate = Date()
		let prev_event_copied = EKEvent.init(eventStore: store)
		prev_event_copied.calendar = previous_event!.calendar
		prev_event_copied.title = previous_event!.title
		prev_event_copied.startDate = Date()
		prev_event_copied.endDate = Date(timeIntervalSinceNow: time * 60)
		try store.save(last_event!, span: .thisEvent, commit: true)
		try store.save(prev_event_copied, span: .thisEvent, commit: true)
		if previous_event!.title != nil {
			print(previous_event!.title!)
		}
	}

default:
	// end current event
	if last_event != nil {
		last_event!.endDate = Date()
		try store.save(last_event!, span: .thisEvent, commit: true)
	}
	// add new event
	var calendar_not_found = true
	for cal in calendars {
		if arguments.count < 1 {
			print(USAGE)
			exit(1)
		} else {

			if (cal.title.lowercased().contains(arguments[1])) {
				calendar_not_found = false
				let new_event = EKEvent.init(eventStore: store)
				new_event.calendar = cal

				var cal_time_and_title = arguments
				if (arguments.contains("at")) {
					let args_splitted = arguments.split(separator: "at")
					cal_time_and_title = Array(args_splitted[0])
					let after_at = Array(args_splitted[1])
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
	}
	if (calendar_not_found) {
		print("no such calendar:", arguments[1])
	}

}
