//
//  ViewController.swift
//  Charger21_Master
//
//  Created by Ruedi Heimlicher on 05.08.2021.
//

import Cocoa
import Foundation
import AVFoundation
import Darwin
import AudioToolbox



let DATA_START_BYTE   = 8    // erstes byte fuer Data auf USB
let BATT_MIN = 2.8
let TEENSYVREF:Float = 249.0 // Korrektur von Vref des Teensy: nomineller Wert ist 256 2.56V


func U8ArrayToHexString(arr: [UInt8]) -> String 
{
   var returnString : String = "" 
   for eachUInt8Byte in arr 
   {   
      //https://stackoverflow.com/questions/24229505/how-to-convert-an-int-to-hex-string-in-swift
      let string2 = String(format:"%02X\t", eachUInt8Byte)
      //print(string2) // prints: "01"
      returnString += string2
    }
   // letzten Tab entfernen
   // https://stackoverflow.com/questions/24122288/remove-last-character-from-string-swift-language
   let template = returnString
   let indexStartOfText = template.index(template.startIndex, offsetBy: 0)
   let indexEndOfText = template.index(template.endIndex, offsetBy: -1)


   // template[indexStartOfText..<indexEndOfText]
   return String(template[indexStartOfText..<indexEndOfText]) 
   //   return returnString.substring(to: returnString.index(before: returnString.endIndex)) 
}

func U8ArrayToIntString(arr: [UInt8]) -> String 
{
   var returnString : String = "" 
   for eachUInt8Byte in arr 
   {   
      //https://stackoverflow.com/questions/24229505/how-to-convert-an-int-to-hex-string-in-swift
      let string2 = String(format:"%02d\t", eachUInt8Byte)
      //print(string2) // prints: "01"
      returnString += string2
   }
   // letzten Tab entfernen
   // https://stackoverflow.com/questions/24122288/remove-last-character-from-string-swift-language
   
   let template = returnString
   let indexStartOfText = template.index(template.startIndex, offsetBy: 0)
   let indexEndOfText = template.index(template.endIndex, offsetBy: -1)
   
   
   // template[indexStartOfText..<indexEndOfText]
   return String(template[indexStartOfText..<indexEndOfText]) 

  //return returnString.substring(to: returnString.index(before: returnString.endIndex)) 
   
}


class ViewController: NSViewController {

   override func viewDidLoad() {
      super.viewDidLoad()

      // Do any additional setup after loading the view.
   }

   override var representedObject: Any? {
      didSet {
      // Update the view, if already loaded.
      }
   }


}

