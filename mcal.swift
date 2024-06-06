import Foundation;import EventKit;setbuf(stdout,nil)
var d=60.0/*min*/;let a=CommandLine.arguments
let USE="""
mcal 2.0 - https://github.com/0ihsan/mcal
Manage your today in macOS/Calendar.app

 mcal \u{001B}[33m<calendar> \u{001B}[32m<minutes> \u{001B}[31m<title>\u{001B}[0m [ at \u{001B}[34m<location>\u{001B}[0m ]
	   - ends current event and creates new event with these args

 mcal \u{001B}[35mshow\u{001B}[0m - show current event
 mcal \u{001B}[35mend\u{001B}[0m  - end current event
 mcal \u{001B}[35mpush\u{001B}[0m [ \u{001B}[33m<calendar> \u{001B}[32m<minutes> \u{001B}[31m<title>\u{001B}[0m [ at \u{001B}[34m<location>\u{001B}[0m ] ]
	   - stitch current event to last event or create new and stitch
 mcal \u{001B}[35mcon\u{001B}[0m  - end current event, continue previous event
 mcal \u{001B}[35mnext\u{001B}[0m - end current event, bring next event to now
 mcal \u{001B}[35mlist\u{001B}[0m - list today's events with relative ids
 mcal \u{001B}[35mhelp\u{001B}[0m - show this page

 c > con	 s > show	 m > move	 p > push
 e > end	 l > list	 n > next	 h > help

\u{001B}[33mEXAMPLE:\u{001B}[0m

 mcal\u{001B}[0m \u{001B}[33mdevelop \u{001B}[32m60 \u{001B}[31mcalendar cli\u{001B}[0m
 mcal\u{001B}[0m \u{001B}[35mpush\u{001B}[33m personal \u{001B}[31mspend time with family\u{001B}[0m at \u{001B}[34mlondon, home\u{001B}[0m
 mcal\u{001B}[0m \u{001B}[33mdevelop \u{001B}[32m120 \u{001B}[31mimprove mcal\u{001B}[0m at \u{001B}[34mhttps://github.com/0ihsan/mcal\u{001B}[0m
 mcal\u{001B}[0m \u{001B}[33mplay \u{001B}[32m30 \u{001B}[31mchess\u{001B}[0m at \u{001B}[34mhttps://lichess.org\u{001B}[0m
 mcal\u{001B}[0m \u{001B}[33mspare \u{001B}[32m15 \u{001B}[31mbreak\u{001B}[0m
"""

if 2>a.count{print(USE);exit(1)}
switch a[1]{
 case "c", "con":print("took \u{001B}[35m",terminator:"");if 2<a.count{d=Double(a[2])!}
 case "e", "end":print("took \u{001B}[35m",terminator:"")
 case "l","list":break
 case "m","move":print("moved from \u{001B}[33m",terminator:"")
 case "n","next":print("started \u{001B}[1;33m",terminator:"")
 case "p","push":print("took \u{001B}[35m",terminator:"")
 case "s","show":break
 case "h","help","-h","--help":print(USE); exit(0)
 default:if 2<a.count{d=Double(a[2])!}else{print(USE);exit(1)}}

var s=EKEventStore()
switch EKEventStore.authorizationStatus(for:.event){
 case .authorized:break
 case .denied:print("Settings > Privacy & Security > Calendars > Terminal"); exit(1)
 case .notDetermined:s.requestFullAccessToEvents(completion:{(granted:Bool,error:Error?)->Void in if granted{print("granted")}else{print("access denied")}})
 default:fputs("?",stderr)}

let t=Date();let f=DateComponentsFormatter();f.allowedUnits=[.hour,.minute];f.maximumUnitCount=2;f.unitsStyle = .abbreviated;let c=s.calendars(for:.event);let m=Calendar.current.startOfDay(for:t);let n=Calendar.current.date(byAdding:.day,value:1,to:m)!
let ec=s.events(matching:s.predicateForEvents(withStart:t,end:t,calendars:c)).filter{e in return !e.isAllDay}
let em=s.events(matching:s.predicateForEvents(withStart:m,end:t,calendars:c)).filter{e in return !e.isAllDay}
let en=s.events(matching:s.predicateForEvents(withStart:t,end:n,calendars:c)).filter{e in return !e.isAllDay}
var e:EKEvent?;var l:EKEvent?;var p:EKEvent?;if ec.count>0{e=ec.last};if em.count>0{l=em.last};if em.count>1{p=em[em.count-2]}
switch a[1]{

 case "c","con":
  if nil != l && nil != p{
   l!.endDate=t
   print(f.string(from:l!.startDate,to:t)!+"\u{001B}[0m:\u{001B}[33m "+l!.title!+"\u{001B}[0m\ncontinue: \u{001B}[1;33m",terminator:"")
   let cpy=EKEvent.init(eventStore:s);cpy.calendar=p!.calendar;cpy.location=p!.location;cpy.notes=p!.notes;cpy.calendar=p!.calendar;cpy.title=p!.title;cpy.startDate=t;cpy.endDate=Date(timeIntervalSinceNow:60*d)
   try s.save(l!,span:.thisEvent,commit:true)
   try s.save(cpy,span:.thisEvent,commit:true)
   if nil != p!.title{fputs(p!.title!+"\u{001B}[0m",stdout)
    if nil != p?.location{fputs(" at \u{001B}[34m\(p!.location!)",stdout)}
    putchar(10)}
  }else{fputs("\r\u{001B}[0;31mno event found since\u{001B}[35m midnight\u{001B}[0m\n",stderr)}

 case "e","end":
  if nil==l{fputs("\r\u{001B}[0;31mno event found since\u{001B}[35m midnight\u{001B}[0m\n",stderr)}
  else{l!.endDate=t;try s.save(l!,span:.thisEvent,commit:true)
   if nil != l!.title{print(f.string(from:l!.startDate,to:l!.endDate)!+"\u{001B}[0m: \u{001B}[1;33m"+l!.title!)}}

 case "l","list":
  for (i,x) in em.enumerated(){
   let loc=nil != x.location ? " at \u{001B}[34m\(x.location!)\u{001B}[0m" : ""
   let dat=x.startDate.fmt(f:"hh:mm")
   print("[\u{001B}[32m\(em.count-i-1)\u{001B}[0m] \(dat) \u{001B}[35m\(x.calendar!.title)\u{001B}[0m \u{001B}[33m\(x.title!)\u{001B}[0m\(loc)")}
  print("    ---")
  for x in en{
   let loc=nil != x.location ? " at \u{001B}[34m\(x.location!)\u{001B}[0m" : ""
   let dat=x.startDate.fmt(f:"hh:mm")
   print("    \(dat) \u{001B}[35m\(x.calendar!.title)\u{001B}[0m \u{001B}[33m\(x.title!)\u{001B}[0m\(loc)")}

 case "m","move":
  if 4>a.count{fputs("\r\u{001B}[0;31mmove <calendar_name> <event_id>\u{001B}[0m\n\nevent_id:\n  0: current/last event\n  1: previous event\n  2..\n  ..\n",stderr);exit(1)}
  let i=Int(a[3])!
  if (i+1)>em.count{fputs("\r\u{001B}[31mevent \(i) not found, try: \u{001B}[33mmcal list\u{001B}[0m\n",stderr);exit(1)}
  var nocal=true
  for cal in c{
   if cal.title.lowercased().contains(a[2].lowercased()){
    nocal=false
    let up=em.reversed()[i];let old=up.calendar.title;up.calendar=cal
    try s.save(up,span:.thisEvent,commit:true)
    print("\(old)\u{001B}[0m to \u{001B}[1;33m\(up.calendar.title)\u{001B}[0m")
    break}}
  if nocal{fputs("\r\u{001B}[0;31mno such calendar: \u{001B}[1;31m\(a[2])\u{001B}[0m\n",stderr)}

 case "n","next":
  var i=0
  if nil != e{e!.endDate=t; try s.save(e!,span:.thisEvent,commit:true);i+=1
  }else if nil != l{l!.endDate=t;try s.save(l!,span:.thisEvent,commit:true)}
  if 0<en.count-ec.count{let ne=en[i]; ne.startDate=t;ne.endDate=Date(timeIntervalSinceNow:60*d)
   try s.save(ne,span:.thisEvent,commit:true)
   let loc=nil != ne.location ? "\u{001B}[0m at \u{001B}[34m\(ne.location!)\u{001B}[0m" : ""
   print("\(ne.title!)\(loc)")
   //if nil != ne.location{print("\u{001B}[0m at\u{001B}[34m "+ne.location!,"\u{001B}[0m")}
  }else{fputs("\r\u{001B}[0;31mno event found\u{001B}[35m until midnight\u{001B}[0m\n",stderr)}

 case "p","push":
  if nil==l{fputs("\r\u{001B}[0;31mdon't know where to push, no last event\u{001B}[0m\n",stderr);exit(1)}
  if nil != e{e!.endDate=t;e!.startDate=p!.endDate;try s.save(e!,span:.thisEvent,commit:true)
   print(f.string(from:e!.startDate,to:e!.endDate)!+"\u{001B}[0m: \u{001B}[1;33m"+e!.title!)
  }else{/*no curr event,create new*/
   var nocal=true
   for cal in c{
    if 3>a.count{fputs("\r\u{001B}[0;31mno current event to push\n",stderr);exit(1)
    }else if cal.title.lowercased().contains(a[2].lowercased()){
     nocal=false;let ne=EKEvent.init(eventStore:s);ne.calendar=cal
     var cdt=a //cal,dur,title
     if a.contains("at"){
      let sp=a.split(separator:"at");cdt=Array(sp[0]);let loc=Array(sp[1])
      if 0<loc.count{ne.location=loc.joined(separator:" ")}}
     if 3<cdt.count{ne.title=cdt.dropFirst(3).joined(separator:" ")
     }else if 3==cdt.count{ne.title=cdt.dropFirst(2).joined(separator:" ")
     }else{print(USE);exit(1)}
     ne.startDate=l!.endDate;ne.endDate=t
     try s.save(ne,span:.thisEvent,commit:true)
     print(f.string(from:ne.startDate,to:ne.endDate)!+"\u{001B}[0m: \u{001B}[1;33m"+ne.title!)
     break}}
   if nocal{fputs("\r\u{001B}[0;31mno such calendar: \u{001B}[1;31m\(a[2])\u{001B}[0m\n",stderr)}}

 case "s","show":
  if nil != e{
   fputs("\n  \u{001B}[1;33m",stderr);print(e?.title ?? "",terminator:"");fputs("\u{001B}[0m\n",stderr);putchar(9)
   fputs("\ncalendar: \u{001B}[36m",stderr);print(e?.calendar.title ?? "",terminator:"");fputs("\u{001B}[0m",stderr);putchar(9)
   fputs("\n started: \u{001B}[35m",stderr);print(f.string(from:e!.startDate,to:t)!,terminator:"");fputs("\u{001B}[0m ago",stderr)
   if nil != e?.location{putchar(9);fputs("\nlocation: \u{001B}[34m",stderr);print(e!.location!,terminator:"");fputs("\u{001B}[0m",stderr)}
   if nil != e?.notes{putchar(9);fputs("\n   notes:\n------",stderr);putchar(10);fputs(e!.notes!,stdout);fputs("\n------",stderr)}
   putchar(10)
  }else{fputs("\u{001B}[31mno current event\u{001B}[0m\n",stderr)
   if nil != l?.title{
    fputs("last was: \u{001B}[1;33m[\(l!.calendar.title)] \(l!.title!)\u{001B}[0m ",stderr)
    fputs("\u{001B}[35m\(f.string(from:l!.endDate,to:t)!)\u{001B}[0m ago\n",stderr)}}

 default:/*create new event*/
  if nil != l{l!.endDate=t;try s.save(l!,span:.thisEvent,commit:true)} //end current
  var nocal=true
  for cal in c{
   if 1>a.count{print(USE);exit(1)
   }else{
    if cal.title.lowercased().contains(a[1].lowercased()){
    nocal=false;
    let ne=EKEvent.init(eventStore:s);ne.calendar=cal
    var cdt=a //cal,dur,title
    if a.contains("at"){
     let sp=a.split(separator:"at");cdt=Array(sp[0]);let loc=Array(sp[1])
     if 0<loc.count{ne.location=loc.joined(separator:" ")}}
    if 3<cdt.count{ne.title=cdt.dropFirst(3).joined(separator:" ")
    }else if 3==cdt.count{ne.title=cdt.dropFirst(2).joined(separator:" ")
    }else{print(USE);exit(1)}
    ne.startDate=t;ne.endDate=Date(timeIntervalSinceNow:60*d)
    try s.save(ne,span:.thisEvent,commit:true)
    print("created. ends at\u{001B}[1;35m",Date.init(timeIntervalSinceNow:60*d).fmt(f:"HH:mm"),"\u{001B}[0m")
    break}}}
  if nocal{print("\r\u{001B}[0;31mno such calendar: \u{001B}[1;31m\(a[1])\u{001B}[0m")}

}
extension Date{func fmt(f:String)->String{let x=DateFormatter();x.dateFormat=f;return x.string(from:self)}}
