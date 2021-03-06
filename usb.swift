//
//  Netz.swift
//  SwiftStarter
//
//  Created by Ruedi Heimlicher on 30.10.2014.
//  Copyright (c) 2014 Ruedi Heimlicher. All rights reserved.
//

import Cocoa
import Foundation
import AVFoundation
import Darwin

// SPI
var						spistatus=0;

//#define TIMER0_STARTWERT					0x80
//#define SPI_BUFSIZE							48
let TIMER0_STARTWERT			=		0x80
let SPI_BUFSIZE		=					48
let BUFFER_SIZE:Int   = Int(BufferSize())


open class usb_teensy: NSObject
{
   var hid_usbstatus: Int32 = 0
   var usb_count: UInt8 = 0
   var read_byteArray = [UInt8](repeating: 0x00, count: BUFFER_SIZE)
   var last_read_byteArray = [UInt8](repeating: 0x00, count: BUFFER_SIZE)
  
   
   /*
   char*      sendbuffer;
   sendbuffer=malloc(USB_DATENBREITE);
*/
   var write_byteArray: Array<UInt8> = Array(repeating: 0x00, count: BUFFER_SIZE)
  
   
   // var testArray = [UInt8]()
   var testArray: Array<UInt8>  = [0xAB,0xDC,0x69,0x66,0x74,0x73,0x6f,0x64,0x61]
   
   var read_OK:ObjCBool = false
   
   var new_Data:ObjCBool = false
   
   var manustring:String = ""
   var prodstring:String = ""
   
   var datatruecounter = 0
   var datafalsecounter = 0
   
   
   override init()
   {
      super.init()
   }
   
   
   open func USBOpen()->Int32
   {
      var r:Int32 = 0
      print("func usb_teensy.USBOpen hid_usbstatus: \(hid_usbstatus)")
      if (hid_usbstatus > 0)
      {
         print("func usb_teensy.USBOpen USB schon offen")
         let alert = NSAlert()
         alert.messageText = "USB Device"
         alert.informativeText = "USB ist schon offen"
         alert.alertStyle = .warning
         alert.addButton(withTitle: "OK")
        // alert.addButton(withTitle: "Cancel")
         let antwort =  alert.runModal() == .alertFirstButtonReturn
         return 1;
      }
      //int rawhid_open(int max, int vid, int pid, int usage_page, int usage)
  //    let    out = rawhid_open(1, 0x16C0, 0x0486, 0xFFAB, 0x0200)
      
      let    out = rawhid_open(1, 0x16C0, 0x0486, 0xFFAB, 0x0200)
     
      
      print("func usb_teensy.USBOpen out: \(out)")
      
      hid_usbstatus = out as Int32;
      
      if (out <= 0)
      {
         NSLog("USBOpen: no rawhid device found");
         //[AVR setUSB_Device_Status:0];
      }
      else
      {
         NSLog("USBOpen: found rawhid device hid_usbstatus: %d",hid_usbstatus)
         let manu   = get_manu()
         var manustr:String = "--"
         if (manu != nil)
         {
            manustr = String(cString: manu!)
            
         }
         if (manustr.isEmpty)
         {
            manustring = "-"
         }
         else
         {
            manustring = manustr //String(cString: UnsafePointer<CChar>(manustr))
         }
         
         let prod = get_prod();
         //fprintf(stderr,"prod: %s\n",prod);
         let prodstr:String = String(cString: prod!)
         // https://stackoverflow.com/questions/40685592/comparing-non-optional-any-to-nil-is-always-false
         let anyprodstr : Any? = prodstr
         if (anyprodstr == nil)
         //if (prodstr != nil)
         {
            prodstring = "-"
         }
         else
         {
            prodstring = String(cString: UnsafePointer<CChar>(prod!))
         }
     //    var USBDatenDic = ["prod": prod, "manu":manu]
         
      }
      
      
      return out;
   } // end USBOpen
   
   open func manufactorer()->String?
   {
      return manustring
   }

   open func producer()->String?
   {
      return prodstring
   }
   
   
   open func close_hid()
   {
      
      rawhid_close(0);
   }
   
   
   open func status()->Int32
   {
      return hid_usbstatus
   }
   
   open func start_read_USB(_ cont: Bool)-> Int
   {
      read_OK = ObjCBool(cont)
      let timerDic:NSMutableDictionary  = ["count": 0]
      
      let result = rawhid_recv(0, &read_byteArray, Int32(BUFFER_SIZE), 220);
      
      print("\n************    report_start_read_USB result: \(result) cont: \(cont)")
      //print("usb.swift start_read_byteArray start: *\n\(read_byteArray)*")
      
      let nc = NotificationCenter.default
      nc.post(name:Notification.Name(rawValue:"newdata"),
              object: nil,
              userInfo: ["message":"neue Daten", "data":read_byteArray])

      // var somethingToPass = "It worked in teensy_send_USB"
      let xcont = cont;
      
      if (xcont == true)
      {
         var timer : Timer? = nil
         timer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(usb_teensy.cont_read_USB(_:)), userInfo: timerDic, repeats: true)
      }
      return Int(result) //
   }
   
   
   @objc open func cont_read_USB(_ timer: Timer)
   {
      //print("*cont_read_USB read_OK: \(read_OK)")
      if (read_OK).boolValue
      {
         //var tempbyteArray = [UInt8](count: 32, repeatedValue: 0x00)
         // https://stackoverflow.com/questions/45415901/simultaneous-accesses-to-0x1c0a7f0f8-but-modification-requires-exclusive-access
         
         var result = rawhid_recv(0, &read_byteArray, Int32(BUFFER_SIZE), 150)
         
 
   //      print("*cont_read_USB result: \(result) \((String(format:"%02X", read_byteArray[0]))) \((String(format:"%02X", read_byteArray[1]))) \((String(format:"%02X", read_byteArray[2]))) \((String(format:"%02X", read_byteArray[3])))")
          //print("tempbyteArray in Timer: *\(read_byteArray)*")
         // var timerdic: [String: Int]
         
         /*
          if  var dic = timer.userInfo as? NSMutableDictionary
          {
          if var count:Int = timer.userInfo?["count"] as? Int
          {
          count = count + 1
          dic["count"] = count
          //dic["nr"] = count+2
          //println(dic)
          usb_count += 1
          }
          }
          */
         //      let timerdic:Dictionary<String,Int!> = timer.userInfo as Dictionary<String,Int!>
         //let messageString = userInfo["message"]
         //       var tempcount = timerdic["count"]!
         
         //timer.userInfo["count"] = tempcount + 1
         
         //print("+++ new read_byteArray in Timer:")
         /*
          for  i in 0...12
          {
          print(" \(read_byteArray[i])")
          }
          println()
          for  i in 0...12
          {
          print(" \(last_read_byteArray[i])")
          }
          println()
          println()
          */
         
         
         
         //timerdic["count"] = 2
         
         // var count:Int = timerdic["count"]
         
         //timer.userInfo["count"] = count+1
         if !(last_read_byteArray == read_byteArray)
         {
            //print(" new read_byteArray in Timer")
            last_read_byteArray = read_byteArray
            new_Data = true
            datatruecounter += 1
            let codehex = read_byteArray[0]
            
            // http://dev.iachieved.it/iachievedit/notifications-and-userinfo-with-swift-3-0/
             let nc = NotificationCenter.default
             nc.post(name:Notification.Name(rawValue:"newdata"),
             object: nil,
             userInfo: ["message":"neue Daten", "data":last_read_byteArray])
            
           // print("+ new read_byteArray in Timer:", terminator: "")
            //for  i in 0...31
            //{
              // print(" \(read_byteArray[i])", terminator: "")
            //}
            //print("")
            //let stL = NSString(format:"%2X", read_byteArray[0]) as String
            //print(" * \(stL)", terminator: "")
            //let stH = NSString(format:"%2X", read_byteArray[1]) as String
            //print(" * \(stH)", terminator: "")
            
            //var resultat:UInt32 = UInt32(read_byteArray[1])
            //resultat   <<= 8
            //resultat    += UInt32(read_byteArray[0])
            //print(" Wert von 0,1: \(resultat) ")
            
            //print("")
            //var st = NSString(format:"%2X", n) as String
       //     } // end if codehex
         }
         else
         {
            //new_Data = false
            datafalsecounter += 1
            //print("--- \(read_byteArray[0])\t\(datafalsecounter)")
         }
         //println("*read_USB in Timer result: \(result)")
         
         //let theStringToPrint = timer.userInfo as String
         //println(theStringToPrint)
         //timer.invalidate()
      }
      else
      {
         print("*cont_read_USB timer.invalidate")
         timer.invalidate()
      }
   }
   
   open func stop_read_USB(_ inTimer: Timer)
   {
      read_OK = false
   }


   
   open func start_write_USB()->Int32
   {
      // http://www.swiftsoda.com/swift-coding/get-bytes-from-nsdata/
      // Test Array to generate some Test Data
      //  var testData = NSData(bytes: testArray,length: testArray.count)
     
      if (teensy_present() == false)
      {
         return 0
      }
      if (usb_count < 0xFF)
      {
      usb_count += 1
      }
      else
      {
         usb_count = 0
      }
      
      //data0.intValue = write_byteArray[0]
      /*
      if testArray[0] < 0x80
      {
         testArray[0] += 1
      }
      else{
         testArray[0] = 0
      }

      if testArray[1] < 0x80
      {
         testArray[1] += 17
      }
      else
      {
         testArray[1] = 0
      }

      if testArray[2] < 0x80
      {
         testArray[2] += 23
      }
      else
      {
         testArray[2] = 0
      }
*/
      
      //println("write_byteArray: \(write_byteArray)")
      
      // Test
      //write_byteArray[6] = 43;
      //write_byteArray[7] = 44;

      //print("\nusb.swift  write_byteArray in start_write_USB code: \(write_byteArray[0])\nSettings: ", terminator: "\t")
      var i=0;
      
  /*    i = 0 // 16, beginn Data in USB-Buffer
      while i < DATA_START_BYTE - 1
      {
//         print("\(write_byteArray[i])", terminator: " ")
         i = i+1
      }
    //  print("\nData:")
      //for  i in 0...63
      i = DATA_START_BYTE // 16, beginn Data in USB-Buffer
      while i < BUFFER_SIZE - 1
      {
        // print("\(write_byteArray[i])", terminator: " ")
         i = i+1
      }
  //    print("")
   */   
      //let dateA = Date()
      
      let senderfolg = rawhid_send(0,&write_byteArray, Int32(BUFFER_SIZE), 50)
    
      
      //let dauer1 = Date() //
      
      //let diff =  (dauer1.timeIntervalSince(dateA))
      //print("dauer rawhid_send: \(diff)")

      
      //print("senderfolg: \(senderfolg)", terminator: "\n")
     
      if hid_usbstatus == 0
      {
         
      }
      else
      {
         
         
         
      }
      
      return senderfolg
      
   }
 
   //public func read_byteArray()->

   open func cont_write_USB()->Int32
   {
      //old
      //write_byteArray[3] = packetcount
      
      //write_byteArray[PACKETCOUNT_BYTE] = packetcount
      
      /*
      print("*** cont_write_USB packetcount: \(write_byteArray[PACKETCOUNT_BYTE])")
      var i=0;
      
      print(" write_byteArray\t")
      //for  i in 0...63
      while i < 32
      {
         print(" \(write_byteArray[i])", terminator: "")
         i = i+1
      }
      print("")
      */
//print("a")
      
      let senderfolg = rawhid_send(0,&write_byteArray, Int32(BUFFER_SIZE), 50)
      
      //print("b")
      return senderfolg
   }
   
   open func send_USB()->Int32
   {
      // http://www.swiftsoda.com/swift-coding/get-bytes-from-nsdata/
      // Test Array to generate some Test Data
      //var testData = Data(bytes: UnsafePointer<UInt8>(testArray),count: testArray.count)
         let senderfolg = rawhid_send(0,&write_byteArray, Int32(BUFFER_SIZE), 50)
         
         if hid_usbstatus == 0
         {
            //print("hid_usbstatus 0: \(hid_usbstatus)")
         }
         else
         {
            //print("hid_usbstatus not 0: \(hid_usbstatus)")
            
         }
         
         return senderfolg
      
   }

   open func report_stop_read_USB()
   {
      read_OK = false
   }

   open func getlastDataRead()->[UInt8]
   {
      return last_read_byteArray
   }

   open func teensy_present()->Bool
   {
      return (usb_present() > 0)
   }
   
   open func dev_present()->Int32
   {
      return usb_present()
   }
 
   open func clear_bytearray()
   {
      for index in 0..<read_byteArray.count 
      {
         read_byteArray[index] = 0
      }
      for index in 0..<last_read_byteArray.count 
      {
         last_read_byteArray[index] = 0
      }
      
      
      
      
   }

} // class


open class Hello
{
   open func setU()
   {
      print("Hi Netzteil")
   }
}

