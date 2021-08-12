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

public var lastDataRead = Data.init(count:64)



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



class rDataViewController: NSViewController, NSWindowDelegate, AVAudioPlayerDelegate,NSMenuDelegate,NSTextViewDelegate,NSTabViewDelegate,NSTextDelegate, NSTextFieldDelegate
{
   let notokimage :NSImage = NSImage(named:NSImage.Name("notok_image"))!
   let okimage :NSImage = NSImage(named:NSImage.Name("ok_image"))!

   // Status
   var         masterstatus:UInt8 = 0; // was ist zu tun in der loop? 
   // Variablen
   var usbstatus: __uint8_t = 0
   
   var usb_read_cont = false; // kontinuierlich lesen
   var usb_write_cont = false; // kontinuierlich schreiben
   
   // Logger lesen
   var startblock:UInt16 = 1 // Byte 1,2: block 1 ist formatierung
   var blockcount:UInt16 = 0 // Byte 3, 4: counter beim Lesen von mehreren Bloecken
   
   var downloadblocknummer:UInt16 = 0 // Byte 3, 4: counter beim Lesen von mehreren Bloecken

   var download_totalblocks:UInt16 = 0 // Byte 3, 4: counter beim Lesen von mehreren Bloecken

   var download_intervall:UInt16 = 1 // Intervall aus download
   
   var downloaddatanummer:UInt32 = 0 // Byte 3, 4: counter beim Lesen von mehreren Bloecken

   
   var packetcount :UInt8 = 0 // byte 5: counter fuer pakete beim Lesen eines Blocks 10 * 48 + 32
   var lastpacket :UInt16 = 0 // byte 5: counter fuer pakete beim Lesen eines Blocks 10 * 48 + 32

   var messungDataArray:[[UInt8]] = [[0]]
  
   var loggerDataArray:[[UInt8]] = [[]]
   var DiagrammDataArray:[[Float]] = [[]]
   
   var MessungStartzeit = 0
   var MessungStartnummer:Int = 0
   
   var teensycode:UInt8 = 0
   var selectedDevice:String = ""
    var devicestatus:UInt8 = 0 // kontrolle der gelesenen Device
   
   var spistatus:UInt8 = 0;
   var DiagrammFeld:CGRect = CGRect.zero
   
   var taskArray :[[String:String]] = [[:]]
   
   
   var anzahlChannels = 0
   var anzahlStoreChannels = 1
   var swiftArray: [[String:String]] = [[:]]
   var BereichArray = [[Int:String]]()
   var teensy = usb_teensy()
   
   var   adcfloatarray:[Float] = []
   //https://stackoverflow.com/questions/31736079/swift-associative-array-with-multiple-keysvalues
   struct dataelement
   {
      var channel:Int
      var data:Float
   }
   var datazeile = [Float](repeating:0.0, count:10)
   
   var inputDataFeldstring:String = ""
   var newdata=0;
   
   var analogfloatarray:[Float] = Array(Array(repeating:0.0,count:10))
   var devicefloatarray:[[Float]] = Array(repeating:Array(repeating:0.0,count:10),count:6)

   var messungfloatarray:[[Float]] = Array(repeating:Array(repeating:0.0,count:24),count:6)
   
   var rawdataarray:[[UInt8]] = [Array(repeating:0,count:36)] // raw data vom teensy, mit Header


   var bereicharray:[[String]] = [[]]
   var devicearray:[String] = ["Teensy","Temperatur","ADC12BIT"]
  
  var tempAbszisse:Abszisse!
  
  var ordinateArray:[Abszisse] = [Abszisse]() // Abszissen
  var ordinateFeldArray:[NSRect] = [NSRect](repeating:NSZeroRect, count:8) // Felder der Abszissen
  
  var lastscrollposition:CGFloat = 0
  var lastscrollcounter:Int = 0
  
   var formatter = NumberFormatter()
   
   var programmPList = UserDefaults.standard 
   let defaults = UserDefaults.standard
   
   // https://learnappmaking.com/plist-property-list-swift-how-to/
   struct Preferences: Codable 
   {
      var webserviceURL:String
      var itemsPerPage:Int
      var backupEnabled:Bool
      var robot1_offset:Int
   }

   //MARK: Bytes
  

 
   let TAKT_LO_BYTE    =   14
   let TAKT_HI_BYTE    =   15

   let KANAL_BYTE   =    16 // Begin liste der aktivierte Kanaele der devices
   let LOGGER_SETTING    =  0xB0 // Setzen der Settings fuer die Messungen
   let MESSUNG_DATA    =  0xB1 // Setzen der Settings fuer die Messungen

   let USB_STOP    = 0xAA

   let SAVE_SD_BYTE          =     1 // Uebergeben bei loggersettings

   let READ_ERR_BYTE = 1

   //let ABSCHNITT_BYTE         =     2
   let BLOCKOFFSETLO_BYTE    =     3 // Block auf SD fuer Sicherung
   let BLOCKOFFSETHI_BYTE    =     4

   let BLOCK_ANZAHL_BYTE   = 9 // Anzahl zu lesende Blocks
   let DOWNLOADBLOCKNUMMER_BYTE   =   10 // aktuelle nummer des downloadblocks
   let PACKETCOUNT_BYTE = 2


   let DATACOUNT_LO_BYTE    =   5 // Messung, laufende Nummer auf Block
   let DATACOUNT_HI_BYTE   =   6

   let STARTMINUTELO_BYTE = 5
   let STARTMINUTEHI_BYTE = 6

   let DATA_START_BYTE   = 8    // erstes byte fuer Data auf USB

   let HEADER_SIZE = 16
   let PACKET_SIZE = 24 // Datenbreite fuer USB

   let HEADER_OFFSET  =    4     // Erstes Byte im Block nach BLOCK_SIZE: Daten, die bei LOGGER_NEXT uebergeben werden

   //MARK: Charger Konstanten
   
   let TASK_BYTE = 7
   let STROM_A_L_BYTE  = 8
   let STROM_A_H_BYTE  = 9
   
   let STROM_B_L_BYTE  = 10
   let STROM_B_H_BYTE  = 11
   
   // recv
   let  U_M_L_BYTE = 16
   let  U_M_H_BYTE = 17
   let  U_O_L_BYTE = 18
   let  U_O_H_BYTE = 19
   let  I_SHUNT_L_BYTE = 20
   let  I_SHUNT_H_BYTE = 21

 
   // bits von masterstatus

   let MESSUNG_TEENSY_OK     =   7 // Nur messungen auf teensy
   let MESSUNG_WL_OK         =   6 // messungen der wl-devices abrufen
   let MESSUNG_TAKT_OK       =   5  // messen im Intervall-Takt des timers
   let MESSUNG_RUN:UInt8            =  4 // Messung laeuft

   // Bytes fuer Sicherungsort der Daten auf SD
   let TEENSY_DATA    =    0xFC // Daten des teensy lesen

   let MESSUNG_START   =   0xC0 // Start der Messreihe
   let MESSUNG_STOP   =   0xC1 // Start der Messreihe
   let KANAL_WAHL     =    0xC2 // Kanalwahl
   let READ_START   =   0xCA // Start read

   let SAVE_SD_RUN = 0x02 // Bit 1
   let SAVE_SD_STOP = 0x04 // Bit 2

   let SAVE_SD_RUN_BIT:UInt8 = 1 // Bit 1
   let SAVE_SD_STOP_BIT:UInt8 = 2 // Bit 2

  
 
   // Outlets
   // Diagramm
   @IBOutlet  weak  var datagraph: DataPlot!
   @IBOutlet  weak  var dataScroller: NSScrollView!

   @IBOutlet  weak  var datagraph_Volt: DataPlot!
   @IBOutlet  weak  var dataScroller_Volt: NSScrollView!

   @IBOutlet  weak  var taskTab: NSTabView!
   
   @IBOutlet weak   var save_SD_check: NSButton!
   @IBOutlet  weak  var Start_Messung: NSButton!
   
   @IBOutlet  weak  var manufactorer: NSTextField!
   
   @IBOutlet weak   var Start: NSButton!
   
   @IBOutlet weak   var MessungStartzeitFeld: NSTextField!
   
   @IBOutlet weak   var USB_OK: NSTextField!
   @IBOutlet weak var USB_OK_Feld: NSImageView!
   @IBOutlet weak var check_USB_Knopf: NSButton!
 
   
    @IBOutlet  weak  var Test_Knopf: NSButton!
   
   @IBOutlet  weak  var start_read_USB_Knopf: NSButton!
   @IBOutlet  weak  var stop_read_USB_Knopf: NSButton!
   @IBOutlet  weak  var cont_read_check: NSButton!
   
   @IBOutlet  weak  var start_write_USB_Knopf: NSButton!
   @IBOutlet  weak  var stop_write_USB_Knopf: NSButton!
   @IBOutlet  weak  var cont_write_check: NSButton!
   
   
   @IBOutlet  weak  var codeFeld: NSTextField!
   
   @IBOutlet  weak  var data0: NSTextField!
   
   @IBOutlet  weak  var data1: NSTextField!
   
   @IBOutlet  weak  var inputDataFeld: NSTextView!
   
/*
    @IBOutlet  var write_sd_startblock: NSTextField!
    @IBOutlet  var write_sd_anzahl: NSTextField!
    @IBOutlet  var read_sd_startblock: NSTextField!
    @IBOutlet  var read_sd_anzahl: NSTextField!
    @IBOutlet  var download_sd_progress: NSTextField!
    @IBOutlet  var download_sd_block_progress: NSTextField!
    */
   
   @IBOutlet  weak  var messungcounter: NSTextField!
   @IBOutlet  weak  var blockcounter: NSTextField!
   
   @IBOutlet  weak  var downloadDataFeld: NSTextView!

   @IBOutlet  weak  var H_Feld: NSTextField!
   
   @IBOutlet  weak  var L_Feld: NSTextField!
   
   @IBOutlet weak   var spannungsanzeige: NSSlider!
   @IBOutlet  weak  var extspannungFeld: NSTextField!
   
   @IBOutlet  weak  var spL: NSTextField!
   @IBOutlet  weak  var spH: NSTextField!
   
   @IBOutlet  weak  var teensybatt: NSTextField!
   
   @IBOutlet  weak  var Teensy_Status: NSButton!
 

   @IBOutlet  weak  var readData: NSButton!
  
   @IBOutlet  weak var  Vertikalbalken:rVertikalanzeige!

   // Datum
   @IBOutlet  weak  var sec_Feld: NSTextField!
   @IBOutlet  weak  var min_Feld: NSTextField!
   @IBOutlet  weak  var std_Feld: NSTextField!
   @IBOutlet  weak  var wt_Feld: NSTextField!
   @IBOutlet  weak  var mon_Feld: NSTextField!
   @IBOutlet  weak  var jahr_Feld: NSTextField!
   @IBOutlet  weak  var datum_Feld: NSTextField!
   @IBOutlet  weak  var zeit_Feld: NSTextField!
   @IBOutlet  weak  var tagsec_Feld: NSTextField!
   @IBOutlet  weak  var tagmin_Feld: NSTextField!
   
   
    // ADC
   @IBOutlet  weak  var ADC0LO_Feld: NSTextField!
   @IBOutlet  weak  var ADC0HI_Feld: NSTextField!
   @IBOutlet  weak  var ADC0Feld: NSTextField!
   
   @IBOutlet  weak  var ADC1LO_Feld: NSTextField!
   @IBOutlet  weak  var ADC1HI_Feld: NSTextField!
   @IBOutlet  weak  var ADC1Feld: NSTextField!

   // Logging
   @IBOutlet  weak  var Start_Logger: NSButton!
   @IBOutlet  weak  var Stop_Logger: NSButton!
   
   
   // Einstellungen
   @IBOutlet  weak  var IntervallPop: NSComboBox!
   @IBOutlet  weak  var ZeitkompressionPop: NSComboBox!
   @IBOutlet  weak  var Channels_Feld: NSTextField!
   
   @IBOutlet  weak  var storeChannels_Feld: NSTextField!
   @IBOutlet  weak  var storeChannels_Stepper: NSStepper!
   @IBOutlet  weak  var storeChannels_Pop: NSPopUpButton!

   // mmc
   @IBOutlet  weak  var mmcLOFeld: NSTextField!
   @IBOutlet  weak  var mmcHIFeld: NSTextField!
   @IBOutlet  weak  var mmcDataFeld: NSTextField!

   @IBOutlet  var write_sd_startblock: NSTextField!
   @IBOutlet  var write_sd_anzahl: NSTextField!
   @IBOutlet  var read_sd_startblock: NSTextField!
   @IBOutlet  var read_sd_anzahl: NSTextField!
   @IBOutlet  var download_sd_progress: NSTextField!
   @IBOutlet  var download_sd_block_progress: NSTextField!
   
//MARK: Charger
   @IBOutlet  weak  var StromSlider: NSSlider!
   @IBOutlet  weak  var StromStepper: NSStepper!
   @IBOutlet  weak  var StromFeld: NSTextField!
   
   func windowWillClose(_ aNotification: Notification) {
      print("windowWillClose")
      let nc = NotificationCenter.default
      nc.post(name:Notification.Name(rawValue:"beenden"),
              object: nil,
              userInfo: nil)
      
   }

// MARK: viewDidLoad   
   override func viewDidLoad() 
   {
      super.viewDidLoad()
      view.window?.delegate = self // https://stackoverflow.com/questions/44685445/trying-to-know-when-a-window-closes-in-a-macos-document-based-application
      self.view.window?.acceptsMouseMovedEvents = true

      formatter.maximumFractionDigits = 1
      formatter.minimumFractionDigits = 2
      formatter.minimumIntegerDigits = 1
 
      let newdataname = Notification.Name("newdata")
      NotificationCenter.default.addObserver(self, selector:#selector(newDataAktion(_:)),name:newdataname,object:nil)
      NotificationCenter.default.addObserver(self, selector:#selector(tabviewAktion(_:)),name:NSNotification.Name(rawValue: "tabview"),object:nil)
      NotificationCenter.default.addObserver(self, selector: #selector(beendenAktion), name:NSNotification.Name(rawValue: "beenden"), object: nil)

      defaults.set(25, forKey: "Age")
      defaults.set(true, forKey: "UseTouchID")
      defaults.set(CGFloat.pi, forKey: "Pi")
      
      defaults.set("Paul Hudson", forKey: "Name")
      defaults.set(Date(), forKey: "LastRun")

      USB_OK.textColor = NSColor.red
      USB_OK.stringValue = "??";
  
      IntervallPop.addItems(withObjectValues:["1","2","5","10","20","30","60","120","180","300"])
      IntervallPop.selectItem(at:0)
 
      swiftArray.removeAll()
      var dic = [[String:String]](repeating:["on":"1"], count:20)
      
      dic[0]["on"] = String(1)
      dic[0]["device"] = devicearray[0]
      dic[0]["deviceID"] = "0"
      dic[0]["description"] = "Teensy"
      //dic["A"] = String(0) // Kanaele Analog

      var tempDic = [String:String]()
      tempDic["on"] = String(0)
//      tempDic["device"] = "abcd" //devicearray[0]
 //     tempDic["deviceID"] = "0"
      tempDic["description"] = "teensy"
      tempDic["A0"] = String(0)
      tempDic["analogAtitel"] = "ADC 2\tADC 3\tADC 4\tADC"
      tempDic["A1"] = String(1)
      tempDic["A"] = String(3) // Bits fuer Kanaele Analog
      tempDic["bereich"] = "0-80°\t0-160°\t-30-130°"
      tempDic["analog"] = "3"
      tempDic["bereichwahl"] = "0"
      tempDic["temperatur"] = "16.5°"
      tempDic["batterie"] = "1.0V"
      tempDic["stellen"] = "1"
      tempDic["majorteiley"] = "8"
      tempDic["minorteiley"] = "2"
//      print("tempDic: \(tempDic)")
      
       
      
      swiftArray.append(tempDic )

      
      //MARK: -   datagraph
      
      
      let farbe = NSColor.init(red: (0.0), green: (0.0), blue: (0.0), alpha: 0.0)
      var linienfarbeArray_blue = [NSColor](repeating:farbe, count:8)

      linienfarbeArray_blue[0] = NSColor( red: (0.69), green: (0.69), blue: (0.98), alpha: (1.00))
      linienfarbeArray_blue[1] = NSColor( red: (0.59), green: (0.59), blue: (0.98), alpha: (1.00))
      linienfarbeArray_blue[2] = NSColor( red: (0.50), green: (0.49), blue: (0.98), alpha: (1.00))
      linienfarbeArray_blue[3] = NSColor( red: (0.41), green: (0.39), blue: (0.98), alpha: (1.00))
      linienfarbeArray_blue[4] = NSColor( red: (0.32), green: (0.29), blue: (0.98), alpha: (1.00))
      linienfarbeArray_blue[5] = NSColor( red: (0.23), green: (0.20), blue: (0.98), alpha: (1.00))
      linienfarbeArray_blue[6] = NSColor( red: (0.14), green: (0.10), blue: (0.98), alpha: (1.00))
      linienfarbeArray_blue[7] = NSColor( red: (0.05), green: (0.00), blue: (0.98), alpha: (1.00))      
      var linienfarbeArray_red = [NSColor](repeating:farbe, count:8)

      linienfarbeArray_red[0] = NSColor( red: (0.98), green: (0.57), blue: (0.59), alpha: (1.00))
      linienfarbeArray_red[1] = NSColor( red: (0.98), green: (0.49), blue: (0.52), alpha: (1.00))
      linienfarbeArray_red[2] = NSColor( red: (0.98), green: (0.41), blue: (0.45), alpha: (1.00))
      linienfarbeArray_red[3] = NSColor( red: (0.98), green: (0.32), blue: (0.38), alpha: (1.00))
      linienfarbeArray_red[4] = NSColor( red: (0.98), green: (0.24), blue: (0.31), alpha: (1.00))
      linienfarbeArray_red[5] = NSColor( red: (0.98), green: (0.16), blue: (0.24), alpha: (1.00))
      linienfarbeArray_red[6] = NSColor( red: (0.98), green: (0.08), blue: (0.16), alpha: (1.00))
      linienfarbeArray_red[7] = NSColor( red: (0.98), green: (0.00), blue: (0.09), alpha: (1.00))
      var linienfarbeArray_green = [NSColor](repeating:farbe, count:8)
      
      linienfarbeArray_green[0] = NSColor( red: (0.69), green: (0.98), blue: (0.69), alpha: (1.00))
      linienfarbeArray_green[1] = NSColor( red: (0.60), green: (0.91), blue: (0.60), alpha: (1.00))
      linienfarbeArray_green[2] = NSColor( red: (0.52), green: (0.83), blue: (0.50), alpha: (1.00))
      linienfarbeArray_green[3] = NSColor( red: (0.44), green: (0.76), blue: (0.41), alpha: (1.00))
      linienfarbeArray_green[4] = NSColor( red: (0.35), green: (0.68), blue: (0.32), alpha: (1.00))
      linienfarbeArray_green[5] = NSColor( red: (0.27), green: (0.61), blue: (0.23), alpha: (1.00))
      linienfarbeArray_green[6] = NSColor( red: (0.19), green: (0.53), blue: (0.14), alpha: (1.00))
      linienfarbeArray_green[7] = NSColor( red: (0.11), green: (0.45), blue: (0.05), alpha: (1.00))
      self.datagraph.wantsLayer = true
      
      //self.datagraph.layer?.backgroundColor = CGColor.black
     // self.datagraph.setDatafarbe(farbe:NSColor.red, index:0)
      
      self.datagraph.linienfarbeArray[0] = linienfarbeArray_green
      self.datagraph.linienfarbeArray[1] = linienfarbeArray_blue
      self.datagraph.linienfarbeArray[2] = linienfarbeArray_red
      
      var kanaldic:[String:String] = [:]
      
      kanaldic["taskwahl"] = "0"
      kanaldic["taskcheck"] = "0"
      taskArray.removeAll()
      for _ in 0..<8
      {
         taskArray.append(kanaldic)
      }

      
      taskArray[0]["taskcheck"] = "1" // Ein kanal ist immer aktiviert
      
      taskArray[1]["taskcheck"] = "1" //
      
      taskArray[2]["taskcheck"] = "1" //
  //   taskArray[3]["taskcheck"] = "1" //
      
      taskArray[4]["taskcheck"] = "1" //
      taskArray[5]["taskcheck"] = "1" //

      
      
      
   // aus H0
      /*
       let name = "John Doe"
       let robot1 = 300
 //      robotPList.set(name, forKey: "name")
       robotPList.set(robot1, forKey: "robot1")
       
       var preferences = Preferences(webserviceURL: "https://api.twitter.com", itemsPerPage: 12, backupEnabled: false,robot1_offset: 300)
       
       preferences.robot1_offset = 400
  
       
       let encoder = PropertyListEncoder()
       encoder.outputFormat = .xml
       
       let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Robot/Preferences.plist")
       
       do {
          let data = try encoder.encode(preferences)
          try data.write(to: path)
       } catch {
          print(error)
       }
      
       if  let path        = Bundle.main.path(forResource: "Preferences", ofType: "plist"),
          let xml         = FileManager.default.contents(atPath: path),
          let preferences = try? PropertyListDecoder().decode(Preferences.self, from: xml)
       {
          print(preferences.webserviceURL)
       }

       */
      
   
   }// viewDidLoad

   override func viewDidAppear() 
   {
      print("viewDidAppear")
      let nc = NotificationCenter.default
      var userinformation:[String : Any]
      var manufactorername = "-"
      
      self.view.window?.delegate = self as? NSWindowDelegate 
      print("**********************")
      let erfolg = teensy.USBOpen()
      if erfolg == 1
      {
         USB_OK_Feld.image = okimage
         //manufactorername = teensy.manustring
         usbstatus = 1
         Start_Messung.isEnabled = true
      }
      else
      {
         USB_OK_Feld.image = notokimage
         usbstatus = 0
         Start_Messung.isEnabled = false
      }
      userinformation = ["message":"usb", "usbstatus": usbstatus,"manufactorer": manufactorername] as [String : Any]
      nc.post(name:Notification.Name(rawValue:"usb_status"),
              object: nil,
              userInfo: userinformation)

   }
   
   //MARK: Charger
   @IBAction func reportStromSlider(_ sender: NSSlider)
   {
      print("reportStromSlider index: \(sender.intValue)")
      let strom = sender.intValue
      StromFeld.intValue = strom
      teensy.write_byteArray[TASK_BYTE] = 0xA0;
      teensy.write_byteArray[STROM_A_H_BYTE] = UInt8((strom & 0xFF00) >> 8) // hb
      teensy.write_byteArray[STROM_A_L_BYTE] = UInt8((strom & 0x00FF) & 0xFF) // lb
      StromStepper.integerValue = Int(sender.doubleValue) 
      var senderfolg = 0
      if (usbstatus > 0)
      {
         senderfolg = Int(teensy.send_USB())
      }
      print("reportStromSlider senderfolg: \(senderfolg)")
   }//

   
   @IBAction func reportStromStepper(_ sender: NSStepper)// Obere Grenze
   {
      print("reportStromStepper IntVal: \(sender.integerValue)")
 
      let intpos = sender.integerValue 
   //   StromStepper_H_Feld.integerValue = intpos
      teensy.write_byteArray[TASK_BYTE] = 0xA0;
      teensy.write_byteArray[STROM_A_H_BYTE] = UInt8((intpos & 0xFF00) >> 8) // hb
      teensy.write_byteArray[STROM_A_L_BYTE] = UInt8((intpos & 0x00FF) & 0xFF) // lb
      var senderfolg = 0
      if (usbstatus > 0)
      {
         senderfolg = Int(teensy.send_USB())
      }

      StromSlider.integerValue = Int(sender.doubleValue) 
      print("reportStromStepper StromSlider.integerValue: \(StromSlider.integerValue)")
      
   }
 // MARK: ***        Start Messung  
   @IBAction func report_start_ladung(_ sender: NSButton)
   {
      print("start_messung sender: \(sender.state)") // gibt neuen State an
      teensy.write_byteArray[TASK_BYTE] = 0xC0; // Start Messung
      
      
      var lineindex = 0
      for line in taskArray
      {
         print("kanal: \(lineindex)\t\(String(describing: line["taskcheck"]!))")
         lineindex += 1
      }
      
      
      // Messung starten
      if (sender.state.rawValue == 1)
      {
         self.datagraph.DatenArray.removeAll()
         self.datagraph.wertesammlungarray.removeAll()
         self.rawdataarray.removeAll()
         //teensy.read_byteArray.removeAll()
         rawdataarray.removeAll()
         messungDataArray.removeAll()
         
         blockcounter.intValue = 0
         devicestatus = 0x01
         masterstatus &= ~(1<<MESSUNG_RUN)
         messungcounter.intValue = 0
         //teensybatt.stringValue = "0"
         inputDataFeldstring = ""
         inputDataFeld.string = inputDataFeldstring
         //print("start_messung start ")
         blockcounter.intValue = 0
         //TaskListe.reloadData() // TableView
         devicestatus = 0x01
         masterstatus &= ~(1<<MESSUNG_RUN)
         messungcounter.intValue = 0
         inputDataFeldstring = ""
         inputDataFeld.string = inputDataFeldstring
         //print("start_messung start ")
         
         setSettings()
      } // state 1
      
      // Sichern auf SD?
      var save_SD = save_SD_check?.state.rawValue
      if (save_SD == 0)
      {
         var SD_antwort = dialogAlertMult(message: "Sicherung auf MMC", information: "Messungen auf MMC schreiben", buttonOK: "Sicher", buttonCancel: "Nein")
         print("report_start_ladung antwort: \(SD_antwort)")
         if (SD_antwort == 1000) // JA
         {
            save_SD = 1
            save_SD_check?.state = convertToNSControlStateValue(1)
         }
      }
      
      //         cont_read_check.state = 0;
      for var zeile in teensy.read_byteArray
      {
         zeile = 0
      }
      // Intervall einsetzen
      var index = IntervallPop.indexOfSelectedItem
      //
      if (index < 0)
      {
         index = 0
         IntervallPop.selectItem(at:index)
      }
      let wahl = IntervallPop.objectValueOfSelectedItem as! String
      //print("reportTaskIntervall wahl: \(wahl) index: \(index)")
      
      let integerwahl:UInt16? = UInt16(wahl)
      //print("report_start_ladung integerwahl: \(integerwahl!)")
      // Taktintervall in array einsetzen
      teensy.write_byteArray[TAKT_LO_BYTE] = UInt8(integerwahl! & 0x00FF)
      teensy.write_byteArray[TAKT_HI_BYTE] = UInt8((integerwahl! & 0xFF00)>>8)
      
      print("report_start_ladung kanalstatus:")
      for  kan in 0..<swiftArray.count
      {
         let kanalindex = KANAL_BYTE
         let kanalstatus:UInt8 = UInt8(swiftArray[kan]["A"]!)!
         print("kan: \(kan) kanalstatus: \(kanalstatus)")
         teensy.write_byteArray[KANAL_BYTE + kan] = kanalstatus //kanalauswahl
      }
      
      
      // code setzen
      teensy.write_byteArray[0] = UInt8(MESSUNG_START)
      teensy.write_byteArray[1] = 0
      if (save_SD == 1)
      {
         //teensy.write_byteArray[1] = UInt8(SAVE_SD_RUN)
         teensy.write_byteArray[1] |= (1<<SAVE_SD_RUN_BIT)
      }
      
      //Angabe zum  Startblock aktualisieren
      startblock = UInt16(write_sd_startblock.integerValue)
      read_sd_startblock.intValue = Int32(startblock)
      read_sd_anzahl.intValue = 0
      teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF) // Startblock
      teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)
      
      //print("block lo: \(teensy.write_byteArray[BLOCKOFFSETLO_BYTE]) hi: \(teensy.write_byteArray[BLOCKOFFSETHI_BYTE])")
      
      
      let zeit = tagsekunde()
      //print("start_messung A startblock: \(startblock)  zeit: \(zeit)")
      
      let startminute = tagminute()
      teensy.write_byteArray[STARTMINUTELO_BYTE] = UInt8(startminute & 0x00FF)
      teensy.write_byteArray[STARTMINUTEHI_BYTE] = UInt8((startminute & 0xFF00)>>8)
      
      printarray(arr:teensy.write_byteArray)
      
      DiagrammDataArray.removeAll()
      
      print("report_start_ladung messungcounter intvalue: \(messungcounter.intValue) messungcounter wird 0")
      messungcounter.intValue = 0;
      
      
      let paragraphStyle = NSMutableParagraphStyle()
      // print("tabstops A: \(paragraphStyle.tabStops)")
      
      let tabInterval:CGFloat = 28.0
      paragraphStyle.tabStops.removeAll()
      
      for cnt in 0..<32 
      {    // Add 32 tab stops, at desired intervals...
         paragraphStyle.tabStops.append(NSTextTab(textAlignment: .right, location: (CGFloat(cnt) * tabInterval), options: convertToNSTextTabOptionKeyDictionary([:])))
      }               
      //print("tabstops: \(paragraphStyle.tabStops)")
      
      let tempstring = "Messung tagsekunde: \(zeit)\n"
      //         inputDataFeld.string = "Messung tagsekunde: \(zeit)\n"
      
      let attrdatatext = NSMutableAttributedString(string: tempstring)
      let datatextRange = NSMakeRange(0, tempstring.count)
      attrdatatext.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: datatextRange)
      inputDataFeld.textStorage?.append(attrdatatext)
      
      downloadDataFeld.string = "Messung tagsekunde: \(zeit)\n"
      
      
      dataScroller.documentView?.frame.origin.x = 0
      dataScroller.documentView?.frame.size.width = 1000
      let startscrollpunkt = NSMakePoint(0.0,0.0)
      dataScroller.contentView.scroll(startscrollpunkt)
      self.dataScroller.contentView.needsDisplay = true
      
      delayWithSeconds(1)
      
      
      self.datagraph.initGraphArray()
      self.datagraph.setStartsekunde(startsekunde:self.tagsekunde())
      self.datagraph.setMaxY(maxY: 160)
      self.datagraph.setDisplayRect()
      
      self.usb_read_cont = (self.cont_read_check.state.rawValue == 1) // cont_Read wird bei aktiviertem check eingeschaltet
      
      self.teensy.write_byteArray[0] = UInt8(MESSUNG_START)
      //Do something
      
      let readerr = self.teensy.start_read_USB(true)
      if (readerr == 0)
      {
         print("Fehler in report_start_ladung")
      }
      self.MessungStartzeitFeld.integerValue = self.tagsekunde()
      self.MessungStartzeit = self.tagsekunde()
      
      
      
      
      // send
      var senderfolg = 0
      if (usbstatus > 0)
      {
         senderfolg = Int(teensy.send_USB())
      }
      else
      {
         
         print("start_messung stop")
         stop_messung()
      }
      
   }

   func stop_messung()
   {
      teensy.write_byteArray[1] = 0
      print("stop_messung write_byteArray[1] vor: \(teensy.write_byteArray[1])")
      teensy.write_byteArray[0] = UInt8(MESSUNG_STOP)
      //teensy.write_byteArray[1] = UInt8(SAVE_SD_STOP)
      teensy.write_byteArray[1] |= (1<<SAVE_SD_STOP_BIT)
      print("stop_messung write_byteArray[1] nach: \(teensy.write_byteArray[1])")
 
      
      teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF) // Startblock
      teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)
      
      // in callback-Antwort MESSUNG_STOP verschoben
      //        teensy.read_OK = false
      //        usb_read_cont = false
      //        cont_read_check.state = 0;
      
      print("DiagrammDataArray count: \(DiagrammDataArray.count)")
      
      // var messungstring:String = MessungDataString(data:DiagrammDataArray)
      
      let prefix = datumprefix()
      let intervall = IntervallPop.integerValue
      //let startblock = write_sd_startblock.integerValue
      
      
      var senderfolg = teensy.start_write_USB()
      if (senderfolg > 0)
      {
         NSSound(named: NSSound.Name("Glass"))?.play()         
      }
      print("stop_messung") // gibt neuen State an
      //self.datagraph.printwertesammlung()
      
    //  stop_read_USB(self)
   }
  
   
   //MARK: - Konfig Messung
   func setSettings()
   {
      print("setSettings")
      print("swiftArray")
      for zeile in swiftArray
      {
         print(zeile)
      }
      teensy.write_byteArray[0] = UInt8(LOGGER_SETTING)
      //Task lesen
      
      let save_SD = convertFromNSControlStateValue((save_SD_check?.state)!)
      var loggersettings:UInt8 = 0
      if ((save_SD == 1)) // Daten auf SD sichern
      {
         loggersettings = loggersettings | 0x01 // Bit 0
      }
      
      teensy.write_byteArray[SAVE_SD_BYTE] = loggersettings // byte 1
      //Intervall lesen
      // let selectedItem = IntervallPop.indexOfSelectedItem
      let intervallwert = IntervallPop.intValue
      
      // Taktintervall in array einsetzen
      teensy.write_byteArray[TAKT_LO_BYTE] = UInt8(intervallwert & 0x00FF)
      teensy.write_byteArray[TAKT_HI_BYTE] = UInt8((intervallwert & 0xFF00)>>8)
      
      //    print("reportTaskIntervall teensy.write_byteArray[TAKT_LO_BYTE]: \(teensy.write_byteArray[TAKT_LO_BYTE])")
      // Abschnitt auf SD
      
      // Zeitkompression setzen
      //let selectedKomp = ZeitkompressionPop.indexOfSelectedItem
      let kompressionwertwert = ZeitkompressionPop.intValue
      
      let kompvorgabe = ["zeitkompression":Float(kompressionwertwert)]
      datagraph.setVorgaben(vorgaben:kompvorgabe)
      
      //Angabe zum  Startblock lesen. default ist 0
      startblock = UInt16(write_sd_startblock.integerValue)
      
      // read_sd_startblock.intValue = Int32(startblock)
      teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF) // Startblock
      teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)
      
      // Kanalstatus
      
      // on-Status
      var on_status = 0
      for dev in 0..<swiftArray.count
      {
         let devicedata = swiftArray[dev]
         
         //print("devicedata: \(devicedata)")
         if (devicedata["on"] == "1") // device vorhanden
         {
            //devicestatus |= (1<<UInt8(device))
            on_status |= (1 << dev)
            let analog = UInt8(devicedata["A"]!)! // code fuer tasten des SegmentedControl
            teensy.write_byteArray[KANAL_BYTE + dev] = UInt8(devicedata["A"]!)! // code fuer tasten des SegmentedControl der Analog-Kanaele
         }
         else
         {
            teensy.write_byteArray[KANAL_BYTE + dev] = 0 // device nicht aktiv
         }
      }
      
      print("on_status: (on_status)")
      
      let senderfolg = teensy.start_write_USB()
      if (senderfolg > 0)
      {
         NSSound(named: NSSound.Name("Glass"))?.play()         
      }
      print("setSettings end") 

   }
   
   @IBAction func reportSetSettings(_ sender: NSButton)
   {
      
      print("reportSetSettings")
      setSettings()
      return
   }
   
   
   @IBAction func reportTaskIntervall(_ sender: NSComboBox)
   {
      print("reportTaskIntervall index: \(sender.indexOfSelectedItem)")
      if (sender.indexOfSelectedItem >= 0)
      {
         let wahl = String(describing: sender.objectValueOfSelectedItem!)// as! String
         let index = sender.indexOfSelectedItem
         // print("reportTaskIntervall wahl: \(wahl) index: \(index)")
         // http://stackoverflow.com/questions/24115141/swift-converting-string-to-int
         let integerwahl:UInt16? = UInt16(wahl)
         print("reportTaskIntervall integerwahl: \(integerwahl!)")
         
         if let integerwahl = UInt16(wahl)
         {
            print("By optional binding :", integerwahl) // 20
         }
         
         //et num:Int? = Int(firstTextField.text!);
         // Taktintervall in array einsetzen
         teensy.write_byteArray[TAKT_LO_BYTE] = UInt8(integerwahl! & 0x00FF)
         teensy.write_byteArray[TAKT_HI_BYTE] = UInt8((integerwahl! & 0xFF00)>>8)
         //    print("reportTaskIntervall teensy.write_byteArray[TAKT_LO_BYTE]: \(teensy.write_byteArray[TAKT_LO_BYTE])")
      
         datagraph.setIntervall(intervall:Int(wahl)!)
      
      }
   }
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   @objc func beendenAktion(_ notification:Notification) 
   {
      
      print("beendenAktion")
      NSApplication.shared.terminate(self)
      
      
   }

   @objc func tabviewAktion(_ notification:Notification) 
   {
      let info = notification.userInfo
      let ident:String = info?["ident"] as! String  // 
      //print("Basis tabviewAktion:\t \(ident)")
      selectedDevice = ident
   }
   
   @IBAction func start_read_USB(_ sender: NSButton)
   {
      print("start_read_USB")
      let readerfolg = teensy.start_read_USB(true)
      print("start_read_USB readerfolg: \(readerfolg)")
   }

   @IBAction func stop_read_USB(_ sender: NSButton)
   {
      print("stop_read_USB")
      teensy.report_stop_read_USB()
     // let readerfolg = teensy.start_read_USB(true)
      //print("stop_read_USB readerfolg: \(readerfolg)")
   }

   @IBAction func check_USB(_ sender: NSButton)
   {

         let erfolg = UInt8(teensy.USBOpen())
         usbstatus = erfolg
         print("USBOpen erfolg: \(erfolg) usbstatus: \(usbstatus)")
    //     ordinateArray[0].frame = ordinateFeldArray[3]
    //     ordinateArray[0].needsDisplay = true
         if (rawhid_status()==1)
         {
            // NSBeep()
            //print("status 1")
            USB_OK.textColor = NSColor.green
            USB_OK.stringValue = "OK";
            manufactorer.stringValue = "Manufactorer: " + teensy.manufactorer()!
           // Teensy_Status?.isEnabled = true;
            start_read_USB_Knopf?.isEnabled = true;
            stop_read_USB_Knopf?.isEnabled = true;
            start_write_USB_Knopf?.isEnabled = true;
            stop_write_USB_Knopf?.isEnabled = true;
            Start_Messung?.isEnabled = true;
  //          Set_Settings?.isEnabled = true;
            cont_read_check?.isEnabled = true;
            cont_write_check?.isEnabled = true;
            
            Start_Logger.isEnabled = true
            
            datagraph.clear()
            
            swiftArray[0]["on"] = "1" // teensy ist da
            delayWithSeconds(1)
            NSSound(named: NSSound.Name("Frog"))?.play()
            //NSSound(named: "Frog")?.play()
         }
         else
            
         {
            //print("status 0")
            USB_OK.textColor = NSColor.red
            USB_OK.stringValue = "X";
           // Teensy_Status?.isEnabled = false;
            start_read_USB_Knopf?.isEnabled = false;
            stop_read_USB_Knopf?.isEnabled = false;
            start_write_USB_Knopf?.isEnabled = false;
            stop_write_USB_Knopf?.isEnabled = false;
            cont_read_check?.isEnabled = false;
            cont_write_check?.isEnabled = false;         
            Start_Messung?.isEnabled = false;
    //        Set_Settings?.isEnabled = false;

         }
         print("check_USB antwort: \(teensy.status())")
         
      }
   override var representedObject: Any? {
      didSet {
      // Update the view, if already loaded.
      }
   }
   @objc func newDataAktion(_ notification:Notification) 
   {
      let lastData = teensy.getlastDataRead()
      print("lastData:\n \(lastData[0])  \(lastData[1])  \(lastData[2])  \(lastData[3])   ")
      var ii = 0
      while ii < 10
      {
         
         //print("ii: \(ii)  wert: \(lastData[ii])\t")
         ii = ii+1
      }
      
      return;
      let u = ((Int32(lastData[1])<<8) + Int32(lastData[2]))
      //print("hb: \(lastData[1]) lb: \(lastData[2]) u: \(u)")
      let info = notification.userInfo
      
      //print("info: \(String(describing: info))")
      //print("new Data")
      let data = notification.userInfo?["data"] as! [UInt8]
      //print("data: \(String(describing: data)) \n") // data: Optional([0, 9, 51, 0,....
      
      
      //print("lastDataRead: \(lastDataRead)   ")
      var i = 0
      while i < 10
      {
//         print("i: \(i)  wert: \(lastDataRead[i])\t")
         i = i+1
      }
      var emitter = UInt16(data[13]) << 8  | UInt16(data[12])
      
         print("emitteradresse: \(lastDataRead[10]) emitterwerte: \(lastDataRead[12]) \(lastDataRead[13]) emitter: \(emitter)")
      //emitterFeld.integerValue = Int(emitter)
      if let d = notification.userInfo!["usbdata"]
      {
            
         //print("d: \(d)\n") // d: [0, 9, 56, 0, 0,... 
         let t = type(of:d)
         //print("typ: \(t)\n") // typ: Array<UInt8>
         
         //print("element: \(d[1])\n")
         
  //       print("d as string: \(String(describing: d))\n")
         if d != nil
         {
            //print("d not nil\n")
            var i = 0
            while i < 10
            {
              // print("i: \(i)  wert: \(d![i])\t")
               i = i+1
            }
            
         }
        
         
         //print("dic end\n")
      }
      
      //let dic = notification.userInfo as? [String:[UInt8]]
      //print("dic: \(dic ?? ["a":[123]])\n")
   
   }
   
   func printarray(arr:[UInt8])
   {
      // index schreiben
      for index in 0..<arr.count // data
      {
         print("\(index)\t", terminator: "")
      }
      print("")
      
      for index in 0..<arr.count
      {
         print("\(arr[index])\t", terminator: "")
      }
      
      print ("")

   }

   
   func tagminute()-> Int
   {
      let date = Date()
      let calendar = Calendar.current
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "de_CH")
      
      let stunde = calendar.component(.hour, from: date)
      let minute = calendar.component(.minute, from: date)
      return 60 * stunde + minute
   }
   
   
   func tagsekunde()-> Int
   {
      let date = Date()
      let calendar = Calendar.current
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "de_CH")
      
      let stunde = calendar.component(.hour, from: date)
      let minute = calendar.component(.minute, from: date)
      let sekunde = calendar.component(.second, from: date)
      return 3600 * stunde + 60 * minute + sekunde
   }
   
   func datumstring()->String
   {
      //NSLog(@"%@",[NSLocale currentLocale])
      print("datumstring \(NSLocale.current)")
      
      let date = Date()
      let calendar = Calendar.current
      let jahr = calendar.component(.year, from: date)
      let tagdesmonats = calendar.component(.day, from: date)
      let monatdesjahres = calendar.component(.month, from: date)
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "de_CH")
      
      formatter.dateFormat = "dd.MM.yyyy"
      let datumString = formatter.string(from: date)
      print("datumString: \(datumString)*")
      return datumString
   }
   
   func zeitstring()->String
   {
      // http://dev.iachieved.it/iachievedit/handling-dates-with-swift-3-0/
      let date = Date()
      let calendar = Calendar.current
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "de_CH")
      
      let stunde = calendar.component(.hour, from: date)
      let minute = calendar.component(.minute, from: date)
      let sekunde = calendar.component(.second, from: date)
      formatter.dateFormat = "hh:mm:ss"
      let zeitString = formatter.string(from: date)
      return zeitString
   }
   
   func datumprefix()->String
   {
      // http://dev.iachieved.it/iachievedit/handling-dates-with-swift-3-0/
      let date = Date()
      let calendar = Calendar.current
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "en-CH")
      
      let jahr = calendar.component(.year, from: date)
      let tagdesmonats = calendar.component(.day, from: date)
      let monatdesjahres = calendar.component(.month, from: date)
      let stunde = calendar.component(.hour, from: date)
      let minute = calendar.component(.minute, from: date)
      
      
      
      formatter.dateFormat = "yyMMdd_HHmm"
      let prefixString = formatter.string(from: date)
      return prefixString
   }

   
   func dialogAlertMult(message: String, information: String, buttonOK: String, buttonCancel: String) -> Int
   {
      let alert = NSAlert()
      alert.messageText = message
      alert.informativeText = information
      alert.addButton(withTitle: buttonOK)
      alert.addButton(withTitle: buttonCancel)
      alert.alertStyle = NSAlert.Style.warning
      var antwort = 0
      let fenster = NSApplication.shared.windows.first
        return alert.runModal().rawValue
   }
   

   
   func delayWithSeconds(_ seconds: Double)
   {
      // https://programmingwithswift.com/how-to-add-a-delay-to-code-in-swift/
      DispatchQueue.main.asyncAfter(deadline: .now() + seconds) 
      {
         // print("Async after 2 seconds")
      }
      /*
      DispatchQueue.main.asyncAfter(deadline: .now() + seconds)
      {
         completion()
      }
 */
   }

   func delayWithMilliSeconds(_ millis: Int)
   {
      DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(millis)) 
      {
          print("async after 500 milliseconds")
      }
      /*
     // https://cocoacasts.com/how-to-use-dispatch-after-in-swift-3/
      // milis muss Int sein
      DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(millis), qos: .background)
     {
         completion()
      }
 */
   }
   
   override func controlTextDidChange(_ obj: Notification) {
     let textField = obj.object as! NSTextField
     print("\(textField.stringValue) ident: \(textField.identifier)")
   }
   /*
   public func controlTextDidChange(_ obj: Notification) {
       // check the identifier to be sure you have the correct textfield if more are used 
       if let textField = obj.object as? NSTextField, self.StromFeld.identifier == textField.identifier {
           print("\n\nMy own textField = \(self.StromFeld)\nNotification textfield = \(textField)")
           print("\nChanged text = \(textField.stringValue)\n")
       }
   } 
   */
   
   // MARK: fileprivate
   
   // Helper function inserted by Swift 4.2 migrator.
   fileprivate func convertToOptionalNSUserInterfaceItemIdentifier(_ input: String?) -> NSUserInterfaceItemIdentifier? {
      guard let input = input else { return nil }
      return NSUserInterfaceItemIdentifier(rawValue: input)
   }

   // Helper function inserted by Swift 4.2 migrator.
   fileprivate func convertToNSControlStateValue(_ input: Int) -> NSControl.StateValue {
      return NSControl.StateValue(rawValue: input)
   }

   // Helper function inserted by Swift 4.2 migrator.
   fileprivate func convertToNSTextTabOptionKeyDictionary(_ input: [String: Any]) -> [NSTextTab.OptionKey: Any] {
      return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSTextTab.OptionKey(rawValue: key), value)})
   }

   // Helper function inserted by Swift 4.2 migrator.
   fileprivate func convertFromNSControlStateValue(_ input: NSControl.StateValue) -> Int {
      return input.rawValue
   }

   // Helper function inserted by Swift 4.2 migrator.
   fileprivate func convertFromNSUserInterfaceItemIdentifier(_ input: NSUserInterfaceItemIdentifier) -> String {
      return input.rawValue
   }

   // Helper function inserted by Swift 4.2 migrator.
   fileprivate func convertFromOptionalNSUserInterfaceItemIdentifier(_ input: NSUserInterfaceItemIdentifier?) -> String? {
      guard let input = input else { return nil }
      return input.rawValue
   }

   // Helper function inserted by Swift 4.2 migrator.
   fileprivate func convertToNSUserInterfaceItemIdentifier(_ input: String) -> NSUserInterfaceItemIdentifier {
      return NSUserInterfaceItemIdentifier(rawValue: input)
   }


}

