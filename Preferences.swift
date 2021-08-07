//
//  Preferences.swift
//  DataLogger
//
//  Created by Ruedi Heimlicher on 27.07.2017.
//  Copyright © 2017 Ruedi Heimlicher. All rights reserved.
//

import Foundation

struct Preferences 
{
   // https://www.raywenderlich.com/151748/macos-development-beginners-part-3
   // 1
   var selectedTime: TimeInterval {
      get {
         // 2
         let savedTime = UserDefaults.standard.double(forKey: "selectedTime")
         if savedTime > 0 {
            return savedTime
         }
         // 3
         return 360
      }
      set {
         // 4
         UserDefaults.standard.set(newValue, forKey: "selectedTime")
      }
   }
   
}
