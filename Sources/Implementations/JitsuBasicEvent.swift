//
//  JitsuBasicEvent.swift
//  Jitsu
//
//  Created by Leonid Serebryanyy on 22.06.2021.
//

import Foundation

class JitsuBasicEvent: Event {
	
	var name: EventType
	
	var payload = [String : Any]()
	
	init(name: EventType) {
		self.name = name
	}
}