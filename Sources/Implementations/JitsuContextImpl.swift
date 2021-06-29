//
//  JitsuContextImpl.swift
//  Jitsu
//
//  Created by Leonid Serebryanyy on 17.06.2021.
//

import Foundation


class JitsuContextImpl: JitsuContext {
	
	private var contextValues = [EventType : [JitsuContext.Key : Any]]()
	private var generalContextValues = [JitsuContext.Key : Any]()
	
	private let contextQueue = DispatchQueue(label: "com.jitsu.contextQueue", attributes: .concurrent)
		
	func addValues(_ values: [JitsuContext.Key : Any], for eventTypes: [EventType]?, persist: Bool) {
		contextQueue.async(flags: .barrier) { [self] in
			print("adding \(values) for types: \(String(describing: eventTypes))")
			guard let eventTypes = eventTypes else {
				generalContextValues.merge(values) {(old, new) in return new }
				for eventType in contextValues.keys {
					contextValues[eventType]?.merge(values) {(old, new) in return new }
				}
				// todo: save to coredata
				return
			}
			
			eventTypes.forEach { eventType in
				if contextValues[eventType] == nil {
					contextValues[eventType] = values
				} else {
					contextValues[eventType]?.merge(values) {(old, new) in return new }
				}
				// todo: save to coredata
			}
		}
	}
	
	func removeValue(for key: JitsuContext.Key, for eventTypes: [EventType]?) {
		contextQueue.async(flags: .barrier) { [self] in
			guard let eventTypes = eventTypes else {
				generalContextValues.removeValue(forKey: key)
				
				for eventType in contextValues.keys {
					contextValues[eventType]?.removeValue(forKey: key)
				}
				// todo: save to coredata
				return
			}
			eventTypes.forEach { eventType in
				contextValues.removeValue(forKey: eventType)
			}
			// todo: save to coredata
		}
	}
	
	func values(for eventType: EventType?) -> [String : Any] {
		contextQueue.sync {
			guard let eventType = eventType else {
				return generalContextValues
			}
			let eventSpecificValues = contextValues[eventType] ?? [:]
			return eventSpecificValues.merging(generalContextValues)  {(context, general) in return context }
		}
	}
	
	func clear() {
		contextQueue.async(flags: .barrier) { [self] in
			contextValues.removeAll()
			generalContextValues.removeAll()
			setup {}
		}
	}
		
	private var deviceInfoProvider: DeviceInfoProvider
	
	init(deviceInfoProvider: DeviceInfoProvider) {
		self.deviceInfoProvider = deviceInfoProvider
	}
	
	func setup(_ completion: @escaping () -> Void) {
		contextQueue.async(flags: .barrier) { [self] in
			addValues(localeInfo, for: nil, persist: false)
			addValues(appInformation, for: nil, persist: false)
			// todo: addValues: accessibility info
			
			getDeviceInfo { [weak self] deviceInfo in
				guard let self = self else {return}
				self.deviceInfo = deviceInfo
				self.addValues(deviceInfo, for: nil, persist: false)
				completion()
			}
		}
	}
	
	// MARK: - Automatically generated values
		
	private lazy var appInformation: [String: String] = {
		var info = ["src": "jitsu_ios"]
		
		let sdkVersion =  Bundle(for: Self.self).infoDictionary?["CFBundleShortVersionString"] as? String
		info["sdk_version"] = sdkVersion
		
		let mainAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
		info["app_version_id"] = sdkVersion // todo: change in spec
		
		let mainAppBuildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
		info["app_build_id"] = sdkVersion // todo: change in spec
		
		let appName = Bundle.main.infoDictionary?["CFBundleName"] as! String
		info["app_name"] = appName
		
		return info
	}()
	
	private var deviceInfo: [String: Any]?
	
	func getDeviceInfo(_ completion: @escaping ([String: Any]) -> Void) {
		deviceInfoProvider.getDeviceInfo {(deviceInfo) in
			completion([
				"parsed_ua":
					[
						"device_brand": deviceInfo.manufacturer, // e.g. "Apple"
						"ua_family": deviceInfo.deviceModel, // e.g. "iPhone"
						"device_model": deviceInfo.deviceName, // e.g. "iPhone 12"
						"os_family": deviceInfo.systemName, // e.g. "iOS"
						"os_version": deviceInfo.systemVersion, // e.g. "13.3"
						"screen_resolution": deviceInfo.screenResolution // e.g "1440x900" // todo: here?
					]
			])
		}
	}
	
	private lazy var localeInfo: [String: String] = {
		return [
			"user_language": Bundle.main.preferredLocalizations.first ?? Locale.current.languageCode ?? "unknown",
		]
	}()
}