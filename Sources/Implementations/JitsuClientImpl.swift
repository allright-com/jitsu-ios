//
//  JitsuClientImpl.swift
//  Jitsu
//
//  Created by Leonid Serebryanyy on 17.06.2021.
//

import Foundation


class JitsuClientImpl: JitsuClient {
	
	var context: JitsuContext
	
	var userProperties: UserProperties
	
	private var eventsController: EventsController
	
	init(options: JitsuOptions, networkService: NetworkService, deviceInfoProvider: DeviceInfoProvider) {
		let context = JitsuContextImpl(deviceInfoProvider: deviceInfoProvider)
		self.context = context
		
		self.eventsController = EventsController(networkService: networkService)

		let userProperties = JitsuUserPropertiesImpl()
		self.userProperties = userProperties
		
		userProperties.out = { [weak self] event in
			self?.trackEvent(event)
		}
		
		self.eventsQueue.async {
			let setupGroup = DispatchGroup()
			
			setupGroup.enter()
			context.setup {
				setupGroup.leave()
			}
			
			setupGroup.enter()
			userProperties.setup {
				setupGroup.leave()
			}
			
			// init events
			setupGroup.wait()
		}
		
	}
	
	private var eventsQueue = DispatchQueue(label: "com.jitsu.eventsQueue")
	
	// MARK: - Tracking events
	
	func trackEvent(_ event: Event) {
		eventsQueue.async {
			self.eventsController.add(event: event, context: self.context, userProperties: self.userProperties)
			
			if self.eventsController.unbatchedEventsCount >= self.eventsQueueSize {
				self.eventsController.sendEvents()
			}
		}
	}
	
	func trackEvent(name: EventType) {
		let event = JitsuBasicEvent(name: name)
		trackEvent(event)
	}
	
	func trackEvent(name: EventType, payload: [String : Any]) {
		let event = JitsuBasicEvent(name: name)
		event.payload = payload
		trackEvent(event)
	}
	
	// MARK: - Sendinng Batches
	
	var eventsQueueSize: Int = 2
	
	var sendingBatchesPeriod: TimeInterval = 10 // todo
	
	func sendBatch() {
		
	}
	
	// MARK: - On/Off
	
	func turnOff() {
		
	}
	
	func turnOn() {
		
	}
	
}
