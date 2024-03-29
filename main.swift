//
//  main.swift
//  mcal
//
//  Created by ihsan on 2021-4-22...
//

import Foundation
import EventKit

let USAGE = """
\u{001B}[32mmcal\u{001B}[0m 1.1.6
ihsan ihsanl@pm[dot]me
Manage macOS Calendar from command line.

\u{001B}[33mUSAGE:\u{001B}[0m

   \u{001B}[32mmcal\u{001B}[0m <calendar_name> <duration_mins> <event_title> [ at <location> ]

   \u{001B}[32mmcal \u{001B}[34mnow\u{001B}[0m
   \u{001B}[32mmcal \u{001B}[34mend\u{001B}[0m
   \u{001B}[32mmcal \u{001B}[34mpush\u{001B}[0m [ <calendar_name> <event title> [ at <location> ] ]
   \u{001B}[32mmcal \u{001B}[34mcontinue\u{001B}[0m
   \u{001B}[32mmcal \u{001B}[34mnext\u{001B}[0m

\u{001B}[33mALIAS:\u{001B}[0m

   now   -> current
   now   -> what
   e     -> end
   p     -> push
   c     -> continue
   con   -> continue
   start -> next
   s     -> next
   n     -> next

\u{001B}[33mEXAMPLES:\u{001B}[0m

   mcal personal 30 'eat & surf web'
   mcal business 60 develop calendar cli
   mcal spare 15 break
   mcal push personal spend time with family at london, home
   mcal business 120 improve mcal at https://github.com/ihsanturk/mcal
   mcal spare 30 play chess at https://lichess.org
"""

setbuf(stdout, nil);

var duration: Double = 60   // mins

let arguments = CommandLine.arguments
var cmd = ""
if arguments.count > 1 { cmd = arguments[1] }
switch cmd {
case "now", "current", "what", "info":
	break
case "push", "p":
	print("it took \u{001B}[35m", terminator:"")
case "end", "e":
	print("it took \u{001B}[35m", terminator:"")
case "continue", "c", "con":
	print("continue to \u{001B}[1;33m", terminator:"")
	if arguments.count > 2 {duration = Double(arguments[2])!}
case "next", "start", "n", "s":
	print("started to \u{001B}[1;33m", terminator:"")
case "help","h","-h","--help":
	print(USAGE)
	exit(0)
default:
	if arguments.count > 2 {
		duration = Double(arguments[2])!
	} else {
		print(USAGE)
		exit(1)
	}
}

var store = EKEventStore()

switch EKEventStore.authorizationStatus(for: .event) {

	case .notDetermined:
		store.requestFullAccessToEvents(completion:
			{(granted: Bool, error: Error?) -> Void in
				if granted {
					print("access granted")
				} else {
					print("access denied")
				}
		})

	case .denied:
		print("access denied to calendars, try:\n\n",
			"   Preferences > Privacy > Calendars > [Your Terminal] > Check")
		exit(1)

	case .authorized:
		break

	default:
		fputs("what happened there?", stderr)
}


let dateComponentsFormatter = DateComponentsFormatter()
dateComponentsFormatter.allowedUnits = [.second, .minute, .hour]
dateComponentsFormatter.maximumUnitCount = 1
dateComponentsFormatter.unitsStyle = .full

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
	.filter { event in return !event.isAllDay }
let events_since_midnight = store.events(matching: predicate_events_since_midnight)
	.filter { event in return !event.isAllDay }
let events_until_next_midnight = store.events(matching:
	predicate_events_until_next_midnight)
	.filter { event in return !event.isAllDay }

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
			let time_passed = dateComponentsFormatter.string(
				from: last_event!.startDate,
				to: last_event!.endDate)!
			print(time_passed, "\u{001B}[0mto\u{001B}[1;33m", last_event!.title!)
		}
	} else {
		fputs(
			"\r\u{001B}[0;31mno event found since\u{001B}[35m midnight\u{001B}[0m\n",
			stderr)
	}

case "next", "start", "n", "s":
	var next_event_index = 0
	if current_event != nil {
		current_event!.endDate = Date()
		try store.save(current_event!, span: .thisEvent, commit: true)
		next_event_index += 1
	} else if (last_event != nil) {
		last_event!.endDate = Date()
		try store.save(last_event!, span: .thisEvent, commit: true)
	}
	if (events_until_next_midnight.count > 0) {
		let next_event = events_until_next_midnight[next_event_index]
		next_event.startDate = Date()
		next_event.endDate = Date(timeIntervalSinceNow: duration * 60)
		try store.save(next_event, span: .thisEvent, commit: true)
		fputs(next_event.title!, stdout)
		if next_event.location != nil {
			print("\u{001B}[0m at\u{001B}[34m", next_event.location!, "\u{001B}[0m")
		}

	} else {
		fputs(
			"\r\u{001B}[0;31mno event found until\u{001B}[35m next midnight\u{001B}[0m\n",
			stderr)
	}

case "now", "current", "what", "info":
	if current_event != nil  {

		let time_passed = dateComponentsFormatter.string(from: current_event!.startDate, to: Date())!

		fputs("\n  \u{001B}[1;33m",stderr)
		print(current_event?.title ?? "", terminator:"")
		fputs("\u{001B}[0m\n",stderr)

		putchar(9) // 9 is tab character
		fputs("\ncalendar: \u{001B}[36m",stderr)
		print(current_event?.calendar.title ?? "", terminator:"")
		fputs("\u{001B}[0m",stderr)

		putchar(9)
		fputs("\n started: \u{001B}[35m",stderr)
		print(time_passed, terminator:"")
		fputs("\u{001B}[0m ago",stderr)

		if current_event?.location != nil {
			putchar(9)
			fputs("\nlocation: \u{001B}[34m",stderr)
			print(current_event!.location!, terminator:"")
			fputs("\u{001B}[0m",stderr)
		}

		if current_event?.notes != nil {
			putchar(9)
			fputs("\n   notes:\n------",stderr)
			putchar(10) // 10 is new line character
			fputs(current_event!.notes!,stdout)
			fputs("\n------",stderr)
		}

		putchar(10)

	} else {
		fputs("\u{001B}[31mno current event\u{001B}[0m\n", stderr)
		if last_event?.title != nil {
			let time_passed = dateComponentsFormatter.string(
			    from: last_event!.endDate,
			    to: Date())!
			fputs("you did \u{001B}[1;33m\(last_event!.calendar.title) \(last_event!.title!)\u{001B}[0m ", stderr)
			fputs("\u{001B}[35m\(time_passed)\u{001B}[0m ago\n", stderr)
		}
	}

case "continue", "con", "c":
	if last_event != nil && previous_event != nil {
		last_event!.endDate = Date()
		let prev_event_copied = EKEvent.init(eventStore: store)
		prev_event_copied.calendar = previous_event!.calendar
		prev_event_copied.location = previous_event!.location
		prev_event_copied.notes = previous_event!.notes
		prev_event_copied.calendar = previous_event!.calendar
		prev_event_copied.title = previous_event!.title
		prev_event_copied.startDate = Date()
		prev_event_copied.endDate = Date(timeIntervalSinceNow: duration * 60)
		try store.save(last_event!, span: .thisEvent, commit: true)
		try store.save(prev_event_copied, span: .thisEvent, commit: true)
		if previous_event!.title != nil {
			fputs(previous_event!.title!, stdout)
			fputs("\u{001B}[0m", stdout)
			if previous_event?.location != nil {
				fputs(" at \u{001B}[34m\(previous_event!.location!)", stdout)
			}
			putchar(10)
		}
	}

case "push", "p":
	if last_event == nil {
		fputs("\r\u{001B}[0;31mdon't know where to push, no last event :/\u{001B}[0m\n",
			stderr)
		exit(1)
	}
	if current_event != nil {
		current_event!.endDate = Date()
		current_event!.startDate = previous_event!.endDate
		try store.save(current_event!, span: .thisEvent, commit: true)
		let time_passed = dateComponentsFormatter.string(
			from: current_event!.startDate,
			to: current_event!.endDate)!
		print(time_passed, "\u{001B}[0mto\u{001B}[1;33m", current_event!.title!)

	} else { // no event at the moment
		// add new event
		var calendar_not_found = true
		for cal in calendars {
			if arguments.count < 2 {
				print(USAGE)
				exit(1)
			} else {

				if (cal.title.lowercased().contains(arguments[2])) {
					calendar_not_found = false
					let new_event = EKEvent.init(eventStore: store)
					new_event.calendar = cal

					var cal_duration_and_title = arguments
					if (arguments.contains("at")) {
						let args_splitted = arguments.split(separator: "at")
						cal_duration_and_title = Array(args_splitted[0])
						let after_at = Array(args_splitted[1])
						if (after_at.count > 0) {
							new_event.location = after_at.joined(separator: " ")
						}
					}

					if cal_duration_and_title.count > 3 {
						new_event.title = cal_duration_and_title.dropFirst(3).joined(separator: " ")
					} else if (cal_duration_and_title.count == 3) {
						new_event.title = cal_duration_and_title.dropFirst(2).joined(separator: " ")
					} else {
						print(USAGE)
						exit(1)
					}

					new_event.startDate = last_event!.endDate
					new_event.endDate = Date()
					try store.save(new_event, span: .thisEvent, commit: true)
					print(dateComponentsFormatter.string(
						from: new_event.startDate, to: new_event.endDate)!,
						"\u{001B}[0mto\u{001B}[1;33m", new_event.title!)
					break
				}

			}
		}
		if (calendar_not_found) {
			print("\r\u{001B}[0;31mno such calendar: \u{001B}[1;31m\(arguments[2])\u{001B}[0m")
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

				var cal_duration_and_title = arguments
				if (arguments.contains("at")) {
					let args_splitted = arguments.split(separator: "at")
					cal_duration_and_title = Array(args_splitted[0])
					let after_at = Array(args_splitted[1])
					if (after_at.count > 0) {
						new_event.location = after_at.joined(separator: " ")
					}
				}
				
				if cal_duration_and_title.count > 3 {
					new_event.title = cal_duration_and_title.dropFirst(3).joined(separator: " ")
				} else if (cal_duration_and_title.count == 3) {
					new_event.title = cal_duration_and_title.dropFirst(2).joined(separator: " ")
				} else {
					print(USAGE)
					exit(1)
				}

				new_event.startDate = Date()
				new_event.endDate = Date(timeIntervalSinceNow: duration * 60)
				try store.save(new_event, span: .thisEvent, commit: true)
				print(
					"ends at\u{001B}[1;35m",
					Date.init(timeIntervalSinceNow: duration * 60)
						.getFormattedDate(format: "HH:mm"),
					"\u{001B}[0m"
				)
				break
			}

		}
	}
	if (calendar_not_found) {
		print("\r\u{001B}[0;31mno such calendar: \u{001B}[1;31m\(arguments[1])\u{001B}[0m")
	}

}

extension Date {
	func getFormattedDate(format: String) -> String {
		 let dateformat = DateFormatter()
		 dateformat.dateFormat = format
		 return dateformat.string(from: self)
	 }
}

extension Date {
	/// Returns the amount of years from another date
	func years(from date: Date) -> Int {
		return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
	}
	/// Returns the amount of months from another date
	func months(from date: Date) -> Int {
		return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
	}
	/// Returns the amount of weeks from another date
	func weeks(from date: Date) -> Int {
		return Calendar.current.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth ?? 0
	}
	/// Returns the amount of days from another date
	func days(from date: Date) -> Int {
		return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
	}
	/// Returns the amount of hours from another date
	func hours(from date: Date) -> Int {
		return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
	}
	/// Returns the amount of minutes from another date
	func minutes(from date: Date) -> Int {
		return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
	}
	/// Returns the amount of seconds from another date
	func seconds(from date: Date) -> Int {
		return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
	}
	/// Returns the a custom time interval description from another date
	func offset(from date: Date) -> String {
		if years(from: date)   > 0 { return "\(years(from: date))y"   }
		if months(from: date)  > 0 { return "\(months(from: date))M"  }
		if weeks(from: date)   > 0 { return "\(weeks(from: date))w"   }
		if days(from: date)    > 0 { return "\(days(from: date))d"    }
		if hours(from: date)   > 0 { return "\(hours(from: date))h"   }
		if minutes(from: date) > 0 { return "\(minutes(from: date))m" }
		if seconds(from: date) > 0 { return "\(seconds(from: date))s" }
		return ""
	}
}
