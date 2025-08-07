# CarPlay Entitlement Guidelines

## Guidelines for widgets in CarPlay

1. If your widget is not functional or suitable for use in the car, set the disfavored location modifier to include CarPlay.
   • If your widget is a game or requires extensive user interaction. For example, if your widget endlessly refreshes its content each time you tap (more than 6 taps/refreshes).
   • If your widget is non-functional or doesn't serve a practical purpose in the car. For example, if your widget relies on data protection classes A or B it will generally be non-functional in CarPlay because most people use CarPlay while their iPhone is locked.
   • If your widget's primary purpose is to launch your app on iPhone. For example, if the primary purpose of your widget is to launch your app, but your app isn't a CarPlay app, your widget will be non-functional in CarPlay.

For details on the disfavored location modifier, see Widgets in CarPlay.

## Guidelines for all CarPlay apps

1. Your CarPlay app must be designed primarily to provide the specified feature (e.g. CarPlay audio apps must be designed primarily to provide audio playback services, CarPlay parking apps must be designed primarily to provide parking services, etc.).
2. Never instruct people to pick up their iPhone to perform a task. If there is an error condition, such as a required log in, you can let them know about the condition so they can take action when safe. However, alerts or messages must not include wording that asks people to manipulate their iPhone.
3. All CarPlay flows must be possible without interacting with iPhone.
4. All CarPlay flows must be meaningful to use while driving. Don't include features in CarPlay that aren't related to the primary task (e.g. unrelated settings, maintenance features, etc.).
5. No gaming or social networking.
6. Never show the content of messages, texts, or emails on the CarPlay screen.
7. Use templates for their intended purpose, and only populate templates with the specified information types (e.g. a list template must be used to present a list for selection, album artwork in the now playing screen must be used to show an album cover, etc.).
8. All voice interaction must be handled using SiriKit (with the exception of CarPlay navigation apps, see below).

## Additional guidelines for CarPlay audio apps

1. Never show song lyrics on the CarPlay screen.

## Additional guidelines for CarPlay communication (messaging and calling) apps

1. Communication apps must provide either short form text messaging features, VoIP calling features, or both. Email is not considered short form text messaging and is not permitted.
2. Communication apps that provide text messaging features must support all 3 of the following SiriKit intents:
   • Send a message (INSendMessageIntent)
   • Request a list of messages (INSearchForMessagesIntent)
   • Modify the attributes of a message (INSetMessageAttributeIntent)
3. Communication apps that provide VoIP calling features must support CallKit, and the following SiriKit intent:
   • Start a call (INStartCallIntent)

## Additional guidelines for CarPlay driving task apps

1. Driving task apps must enable tasks people need to do while driving. Tasks must actually help with the drive, not just be tasks that are done while driving.
2. Driving task apps must use the provided templates to display information and provide controls. Other kinds of CarPlay UI (e.g. custom maps, real-time video) are not possible.
3. Do not show CarPlay UI for tasks unrelated to driving (e.g. account setup, detailed settings).
4. Do not periodically refresh data items in the CarPlay UI more than once every 10 seconds (e.g. no real-time engine data).
5. Do not periodically refresh points of interest in the POI template more than once every 60 seconds.
6. Do not create POI (point of interest) apps that are focused on finding locations on a map. Driving tasks apps must be primarily designed to accomplish tasks and are not intended to be location finders (e.g. store finders).
7. Use cases outside of the vehicle environment are not permitted.

## Additional guidelines for CarPlay EV charging apps

1. EV charging apps must provide meaningful functionality relevant to driving (e.g. your app can't just be a list of EV chargers).
2. When showing locations on a map, do not expose locations other than EV chargers.

## Additional guidelines for CarPlay fueling apps

1. Fueling apps must provide meaningful functionality relevant to driving (e.g. your app can't just be a list of fueling stations).
2. When showing locations on a map, do not expose locations other than fueling stations.

## Additional guidelines for CarPlay parking apps

1. Parking apps must provide meaningful functionality relevant to driving (e.g. your app can't just be a list of parking locations).
2. When showing locations on a map, do not expose locations other than parking.

## Additional guidelines for CarPlay navigation (turn-by-turn directions) apps

1. Navigation apps must provide turn-by-turn directions with upcoming maneuvers.
2. The base view must be used exclusively to draw a map. Do not draw windows, alerts, panels, overlays, or user interface elements in the base view. For example, don't draw lane guidance information in the base view. Instead, draw lane guidance information as a secondary maneuver using the provided template.
3. Use each provided template for its intended purpose. For example, maneuver images must represent a maneuver and cannot represent other content or user interface elements.
4. Provide a way to enter panning mode. If your app supports panning, you must include a button in the map template that allows people to enter panning mode since drag gestures are not available in all vehicles.
5. Touch gestures must only be used for their intended purpose on the map (pan, zoom, pitch, and rotate).
6. Immediately terminate route guidance when requested. For example, if the driver starts route guidance using the vehicle's built-in navigation system, your app delegate will receive a cancelation notification and must immediately stop route guidance.
7. Correctly handle audio. Voice prompts must work concurrently with the vehicle's audio system (such as listening to the car's FM radio) and your app should not needlessly activate audio sessions when there is no audio to play.
8. Ensure that your map is appropriate in each supported country.
9. Be open and responsive to feedback. Apple may contact you in the event that Apple or automakers have input to design or functionality.
10. Voice control must be limited to navigation features.

## Additional guidelines for CarPlay quick food ordering apps

1. Quick food ordering apps must be Quick Service Restaurant (QSR) apps designed primarily for driving-oriented food orders (e.g. drive thru, pick up) when in CarPlay and are not intended to be general retail apps (e.g. supermarkets, curbside pickup).
2. Quick food ordering apps must provide meaningful functionality relevant to driving (e.g. your app can't just be a list of store locations).
3. Simplified ordering only. Don't show a full menu. You can show a list of recent orders, or favorites limited to 12 items each.
4. When showing locations on a map, do not expose locations other than your Quick Service Restaurants.

---

**Copyright © 2025 Apple Inc. All Rights Reserved.**  
*Document Date: 2025-06-09* 