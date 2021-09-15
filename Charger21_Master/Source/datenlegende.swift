//
//  datenlegende.swift
//  Charger21_Master
//
//  Created by Ruedi Heimlicher on 07.09.2021.
//


import Foundation
import AVFoundation
import Darwin
import AppKit
import Cocoa

func s2(_ wert:CGFloat)->String
{
   return String(format:"%2.2f",wert)
}

struct legendestruct:Codable
{
   var wert:CGFloat
   var index:Int
   var clusterindex:Int
   // NSRect tempRect=NSMakeRect(0,0,30,16);
}

/*
 interface rDatenlegende : NSObject
 {
    float randunten, randoben, abstandnach, abstandvor, mindistanz;
    NSMutableArray* LegendeArray;
 }
 - (void)setVorgabenDic:(NSDictionary*)vorgabendic;
 - (void)setLegendeArray:(NSArray*)array;
 - (NSArray*)LegendeArray;

 end

 */


class rDatenlegende:NSObject
{
   var    randunten:CGFloat = 12, randoben:CGFloat = 0, abstandnach:CGFloat = -1, abstandvor:CGFloat = -1, mindistanz:CGFloat = 16;
   var legendedicarray = [[String:CGFloat]]()
   init(coder  aCoder: NSCoder)
   {
      Swift.print("rDatenlegende init coder")
      super.init()

      
       
   }

   
   
   func setVorgabendic(vorgabendic:[String:CGFloat])
   {
      if let ru = vorgabendic["randunten"]
      {
         randunten = ru
      }
      if let ro = vorgabendic["randoben"]
      {
         randoben = ro
      }
      if let av = vorgabendic["abstandvor"]
      {
         abstandvor = av
      }
      if let an = vorgabendic["abstandnach"]
      {
         abstandnach = an
      }
      if let md = vorgabendic["mindistanz"]
      {
         mindistanz = md
      }
   }// end setVorgabendic

/*   
   struct legendestruct:Codable
   {
      var wert:CGFloat
      var index:Int
   }
*/

   func setStructLegendearray(legendearray:[legendestruct])
   {
      //legendearray:  dics mit index und wert fuer jeden datenpunkt, geordnet nach groesse
      
      var clusterarray:[[[String:CGFloat]]] = [[[:]]]
      //clusterarray.append([["index":0],["wert":0]])
      // Array mit Dics zu jedem Cluster: Array mit Elementen, abstaende usw,
      
      // Abstande einsetzen
      var lastposition:CGFloat = randunten // effektive Position des vorherigen Elements, am Anfang = unterer Rand
      var minposition:CGFloat = randunten     // minimalposition fuer Element
      var distanz:CGFloat = 0     // effektive distanz zum vorherigen Element
      
      
      var clusterindex:Int = 0
      
      for i in 0..<legendearray.count
      {
         let indexzeile:legendestruct = legendearray[i]
         let index = indexzeile.index
         let tempwert:CGFloat = indexzeile.wert// wert, y-Abstand
         
         // wenn genuegend Platz: Legende neben wert
         var legendeposition:CGFloat  = tempwert // lage neben graphlinie
        
         if tempwert < minposition // 
         {
            legendeposition = minposition  // legende wird auf minpos angehoben
            
            if i > 0 // nicht unterste position
            {
               //print("clusterarray.last: \(clusterarray.last) count: \(clusterarray.last?.count)")
               if clusterarray.last?.count == 1 // Array noch leer, objekt einfuegen
               {
                  //print("leer")
                  var prevclusterstruct = legendearray.last// ?? ["clusterindex":0]
                  let l = legendearray.last
                  
                  prevclusterstruct?.clusterindex =  clusterindex
                  let endpos = clusterarray.endIndex
                 // print("last: \(l)")
                  
                  var prevclusterdic:[String:CGFloat] = [:]
                  prevclusterdic["clusterindex"] = CGFloat(clusterindex)
                  //clusterarray[endpos-1].append(prevclusterdic)
                  clusterarray[endpos-1].append(prevclusterdic)
               }
               let anz = clusterarray.endIndex
               
               var clusterdic:[String:CGFloat] = [:]
               clusterdic["legendeposition"] = legendeposition
               clusterdic["clusterindex"] = CGFloat(clusterindex)
               clusterdic["index"] = CGFloat(index)
               clusterdic["wert"] = tempwert
               clusterdic["lastposition"] = lastposition
               clusterdic["abstandvor"] = 0
               clusterarray[anz-1].append(clusterdic)
               
            }
            else
            {
              
               
               
            }
            
            
         }// tempwert < minposition
         else
         {
            minposition = tempwert
            let lastobjcount:Int = clusterarray.last?.count ?? 0
            if lastobjcount > 0
            {
               let last:[[String : CGFloat]] = clusterarray.last ?? [["":0]]
               let lastindex = last.endIndex
               
               let lastlast:[[String : CGFloat]] = clusterarray[lastindex-1]
               let lastlastindex = lastlast.endIndex
               let lastlegendeposition = lastlast[lastlastindex-1]["lastlegendeposition"]
              
               let newlegendeposition:CGFloat = legendeposition-(lastlegendeposition ?? 0) 
               
               //clusterarray[lastindex][0]["abstandnach"] = CGFloat(legendeposition-lastlegendeposition)
               
               clusterarray[lastindex-1][lastlastindex-1]["abstandnach"] = CGFloat(legendeposition-(lastlegendeposition ?? 0))
               clusterindex += 1
            }
         }
         

      }// for legendearray.count
   } 
   
   func setLegendearray(legendearray:[[String:CGFloat]])
   
   {
      //legendearray:  dics mit index und wert fuer jeden datenpunkt, geordnet nach groesse
      print("*****************  setlegendearray start\n")
      var clusterarray:[[[String:CGFloat]]] = [[[:]]] // arrays von werten mit zu kleinem abstand
      //clusterarray.append([["index":0],["wert":0]])
      // Array mit Dics zu jedem Cluster: Array mit Elementen, abstaende usw,
      
      
      // Abstande einsetzen
      var lastposition:CGFloat = randunten // effektive Position des vorherigen Elements, am Anfang = unterer Rand
      var minposition:CGFloat = randunten     // minimalposition fuer Element
      var distanz:CGFloat = 0     // effektive distanz zum vorherigen Element
      
      var clusterindex:CGFloat = 0
      legendedicarray.removeAll()
      var abstandmin:CGFloat = 1000
      // abstaende abfragen: minimum suchen
      var minindex:CGFloat = 0
      var mindicO:[String:CGFloat] = legendearray[0]
      var mindicU:[String:CGFloat] = legendearray[0]
      let mindestabstand:CGFloat = mindistanz
      var mitte:CGFloat  = 0; // schwerpunkt des clusters
      var clusterH:CGFloat  = 0; // hoehe des clusters
      var clusterO:CGFloat  = 0; // oberer Rand
      var clusterU:CGFloat  = 0; // unterer Rand
      
      // ordinateclusterarray
      var ordinateclusterarray:[[[String:CGFloat]]] = [[[:]]] // 
      
      var minabstandarray = [[[String:CGFloat]]]()
      
      var clusterindexset = IndexSet()
      for i in 1..<legendearray.count
      {
         if clusterindexset.contains(i)
         {
            break
         }
         let last = legendearray[i-1]["wert"] ?? 0.0
         let temp = legendearray[i]["wert"] ?? 0.0
         let tempabstand = temp - last
         
         
         if temp - last < mindestabstand // Vorkommen detektiert
         {
            /*
             var clusterdic:[String:CGFloat] = [:]
             clusterdic["legendeposition"] = legendeposition
             clusterdic["clusterindex"] = CGFloat(clusterindex)
             clusterdic["index"] = CGFloat(index)
             clusterdic["wert"] = tempwert
             clusterdic["lastposition"] = lastposition
             clusterdic["abstandvor"] = 0

             */
            var wertsumme:CGFloat = 0 // akkumulierte Hoehe des clusters fuer mittebestimmung
            var tempclusterdicarray = [[[String:CGFloat]]]()  // dics des clusters
            
            var tempBclusterdicarray = [[String:CGFloat]]()  // dics des clusters
            
            //var clusterdic 
            var anzclusterelemente = 0
            var temppositionU:CGFloat = 0
            var temppositionO:CGFloat = 0
            
            abstandmin = temp - last
            mindicO = legendearray[i]  // Ordinate des oberen elements 
            mindicO["clusterindex"] = clusterindex
              
            mindicU = legendearray[i-1] // Ordinate des unteren elements 
            mindicU["clusterindex"] = clusterindex
            
            
            
            anzclusterelemente += 2
            
            // wertsumme:
            wertsumme = mindicO["wert"]! + mindicU["wert"]!
            mitte = (mindicO["wert"]! + mindicU["wert"]!)/CGFloat(anzclusterelemente) // Schwerpunkt des clusters
   
            temppositionO = mitte + mindistanz/2        // legendeposition startelement
            mindicO["legendeposition"] = temppositionO 
            tempclusterdicarray.append([mindicO])
            
            tempBclusterdicarray.append(mindicO)
            
            temppositionU = mitte - mindistanz/2 // legendeposition in legende unteres Element
            mindicU["legendeposition"] = temppositionU
            tempclusterdicarray.append([mindicU])
            
            tempBclusterdicarray.append(mindicU)
            //mitte = (mindicO["wert"]! + mindicU["wert"]!)/2
            
            clusterH = 2*mindistanz // Paket mit 2 Feldern
            clusterO = mitte + mindistanz // aktueller oberer Rand
            clusterU = mitte - mindistanz // aktueller unterer Rand, 
            
            
            minindex = legendearray[i]["index"] ?? 0
            var tempabstanddic:[[String:CGFloat]] = [["index": minindex],["abstand":temp - last]]
            clusterindexset.insert(i)
            clusterindexset.insert(i-1)
    
            
            // groessere werte checken
            var k = i+1 // next position
            while k <  legendearray.count
            {
               let tempwert = legendearray[k]["wert"] ?? 0 // wertdes El
               let tempindex = legendearray[k]["index"] ?? 0 // index des El
               
               if tempwert < clusterO + mindistanz/2 // wert wuerde cluster tangieren
               {
                  if !clusterindexset.contains(k)
                  {
                     print("i: \(i) k: \(k) weiteres Element gefunden oben")
                     wertsumme += tempwert
                     anzclusterelemente += 1
        //             mitte = (mindicO["wert"]! + mindicU["wert"]! + tempwert) / CGFloat(anzclusterelemente)
                     
                     var templegendeelement = legendearray[k]
                     
                     let tempindex = legendearray[k]["index"] ?? 0
                     templegendeelement["clusterindex"] = clusterindex
                     temppositionO += mindistanz // ein schritt hoeher
                     templegendeelement["legendeposition"] = temppositionO
                     
                     // element einsetzen
                     tempclusterdicarray.append([templegendeelement])
                     
                     tempBclusterdicarray.append(templegendeelement)
                     
                     clusterindexset.insert(k)
                     clusterO += mindistanz // cluster reicht hoeher
                     clusterH += mindistanz
                  }
               }
               
  //             minabstandarray.append(tempabstanddic)
               k += 1
            }// while k
            
            // kleinere Werte checken
            var m = i-2 // prev position, i-1 ist bereits gechecked
            while m > 0
            {
               let tempwert = legendearray[m]["wert"] ?? 0
               if tempwert > clusterU - mindistanz/2 // schrift von wert wuerde cluster tangieren
               {
                  if !clusterindexset.contains(m)
                  {
                     print("i: \(i) m: \(m) weiteres Element gefunden unten")
                     wertsumme += tempwert
                     anzclusterelemente += 1
                     var templegendeelement = legendearray[m]
                     let tempindex = legendearray[m]["index"] ?? 0
                     templegendeelement["clusterindex"] = clusterindex
                     temppositionU -= mindistanz // ein schritt tiefer
                     templegendeelement["legendeposition"] = temppositionU
                     
                     // element einsetzen
                     tempclusterdicarray.append([templegendeelement])
                     
                     tempBclusterdicarray.append(templegendeelement)
                     
                     clusterindexset.insert(m)
                     clusterU -= mindistanz // cluster reicht tiefer
                     clusterH += mindistanz
                  }
               }
               m -= 1
            } // while m
            
            print("\ni: \t\(i)\t clusterO: \t\(s2(clusterO)) \tclusterU: \t\(s2(clusterU))  \tclusterH: \t\(s2(clusterH)) \tmitte: \t\(s2(mitte))")

           // print("tempclusterdicarray: \(tempclusterdicarray)  clusterindex:\(clusterindex) clusterO: \(s2(clusterO))  clusterU: \(s2(clusterU))")
            // 
            //tempclusterdicarray = tempclusterdicarray.sort(by: { $0["wert"] ?? 0 < $1["wert"] ?? 0 })
           //      legendedicarray:[[String:CGFloat]] = [[:]]
            
            //var legendearray:[[String:CGFloat]] = [[:]]
            //    legendearray.sort(by: { ($0["index"] ?? 0) < ($1["index"] ?? 0) })
            
            
            //  var tempclusterdicarray = [[[String:CGFloat]]]()
           //
            
            tempBclusterdicarray.sort(by: { ($0["wert"] ?? 0) > ($1["wert"] ?? 0) })
            
            for clusterzeile in tempclusterdicarray
            {
               print("clusterzeile: \(clusterzeile)")
               let lp = clusterzeile[0]["legendeposition"] ?? 0
               print("zeile wert: \t\(String(format:"%2.2f",clusterzeile[0]["wert"] ?? 0)) \tindex: \t\(s2(clusterzeile[0]["index"] ?? 0)) \tlegendeposition: \t\(s2(lp)) \tclusterindex: \t\(s2(clusterzeile[0]["clusterindex"] ?? 0))")
               
               //print(clusterzeile)
            }
            
            print("B")
            print("\ni: \t\(i)\t clusterO: \t\(s2(clusterO)) \tclusterU: \t\(s2(clusterU))  \tclusterH: \t\(s2(clusterH)) \tmitte: \t\(s2(mitte))")

            for clusterzeile in tempBclusterdicarray
            {
               //print("B clusterzeile: \(clusterzeile)")
               let lp = clusterzeile["legendeposition"] ?? 0
               print("B zeile wert: \t\(String(format:"%2.2f",clusterzeile["wert"] ?? 0)) \tindex: \t\(s2(clusterzeile["index"] ?? 0)) \tlegendeposition: \t\(s2(lp)) \tclusterindex: \t\(s2(clusterzeile["clusterindex"] ?? 0))")
               
               //print(clusterzeile)
            }
          
            
            
            clusterindex += 1
         } // if < mindestabstand
 
         
      } // for i .. legendearray count
      print("clusterindexset count: \(clusterindexset.count)")
      /*
      print("\nminabstandarray:")
      for zeile in minabstandarray
      {
         print(zeile)
      }
      print("minabstandarray: \(minabstandarray)")
      
      print("\n")
     */
      
      
      for i in 0..<legendearray.count
      {
         
         let indexzeile:[String:CGFloat] = legendearray[i]
         let index = indexzeile["index"]
         let tempwert:CGFloat = indexzeile["wert"] ?? 0 // wert, y-Abstand
         
         // wenn genuegend Platz: Legende neben wert
         var legendeposition:CGFloat  = tempwert // lage neben graphlinie
        
         if tempwert < minposition // 
         {
            legendeposition = minposition  // legende wird auf minpos angehoben
            
            if i > 0 // nicht unterste position
            {
               //print("clusterarray.last: \(clusterarray.last) count: \(clusterarray.last?.count)")
               if clusterarray.last?.count == 1 // Array noch leer, objekt einfuegen
               {
                  //print("leer")
                  var prevclusterdic:[String:CGFloat] = legendearray.last ?? ["":0]// ?? ["clusterindex":0]
                  let l = legendearray.last
                  
                  prevclusterdic["clusterindex"] = clusterindex
                  let endpos = clusterarray.endIndex
                  //print("last: \(l)")
                  clusterarray[endpos-1].append(prevclusterdic)
               
               }
               let anz = clusterarray.endIndex
               var clusterdic:[String:CGFloat] = [:]
               clusterdic["legendeposition"] = legendeposition
               clusterdic["clusterindex"] = clusterindex
               clusterdic["index"] = index
               clusterdic["wert"] = tempwert
               clusterdic["lastposition"] = lastposition
               clusterdic["abstandvor"] = 0
               clusterarray[anz-1].append(clusterdic)
               
            }
            else // erstes Element
            {
            }
            
            
         }// tempwert < minposition
         else // abstand ausreichend, incl randunten beim ersten Objekt
         {
            minposition = tempwert
            // Cluster fertig, neuen Array fuer eventuellen naechsten Cluster anfuegen
            let lastobjcount:Int = clusterarray.last?.count ?? 0
            if lastobjcount > 0 // der letzte Cluster hatte Elemente
            {
               var lastlegendeposition:CGFloat = 0
               let last:[[String : CGFloat]] = clusterarray.last ?? [["":0]]
               let lastindex = last.count
               if lastindex > 0
               {
                  
                  let lastlast:[String : CGFloat] = last[lastindex-1]
                  let lastlastindex = lastlast.count
                  
                  
                  if lastlastindex > 0
                  {
                     lastlegendeposition = lastlast["legendeposition"] ?? 0
                     //clusterarray[lastindex-1][0]["abstandnach"] = CGFloat(legendeposition-(lastlegendeposition ))

                  }
                  

               }  
               let newlegendeposition:CGFloat = legendeposition-(lastlegendeposition ?? 0) 
               
               //clusterarray[lastindex][0]["abstandnach"] = CGFloat(legendeposition-lastlegendeposition)
               
     //          clusterarray[lastindex-1][lastlastindex-1]["abstandnach"] = CGFloat(legendeposition-(lastlegendeposition ?? 0))
              // clusterarray.append([[ : ]])
               clusterindex += 1
            } // der letzte Cluster hatte Elemente
         }
         distanz = legendeposition-distanz
          
         var legendedic:[String:CGFloat] = [:]
         legendedic["legendeposition"] = legendeposition
         legendedic["clusterindex"] = clusterindex
         legendedic["index"] = index
         legendedic["wert"] = tempwert
         legendedic["lastposition"] = lastposition
         legendedic["abstandvor"] = distanz
         legendedicarray.append(legendedic)
         
         lastposition = legendeposition
         minposition += mindistanz
         

      }// for legendearray.count
//      print("*** clusterarray vor: \(clusterarray)")
      
      //let i = legendedicarray[0]["index"]
      var legendeindexarray:[CGFloat] = []
      legendeindexarray.removeAll()
     
      
      for line in legendedicarray
      {
 //        print("legendedicarray line: \(line)")
         legendeindexarray.append(line["index"] ?? 0)
      }
//      print("legendeindexarray: \(legendeindexarray)")      
      
      for k in 0..<clusterarray.endIndex
      {
 //        print("k: \(k)")
         /*
         for l in 0..<clusterarray[k].endIndex
         {
         print("l: \(l) data: \(clusterarray[k][l])")
         }
         */
         var verschiebung:CGFloat  = 0
         var tempclusterarrayzeile = clusterarray[k]
         
         if tempclusterarrayzeile.count > 0
         {
            var tempabstandvor:CGFloat  = tempclusterarrayzeile[0]["abstandvor"] ?? abstandvor
         
            // Differenz zwischen legendeposition und wert des obersten Elements minus gleiche Differnz des untersten Elements ergibt doppelte Verschiebung
            let lastlegendeposition = tempclusterarrayzeile.last?["legendeposition"] ?? 0
            let startlegendeposition = tempclusterarrayzeile[0]["legendeposition"] ?? 0
            verschiebung = lastlegendeposition - startlegendeposition
            
            verschiebung /= 2
 //           print("zeile \(k) verschiebung: \(verschiebung) tempabstandvor: \(tempabstandvor) mindistanz: \(mindistanz)")
            if verschiebung > tempabstandvor - mindistanz // Verschiebung abzueglich zweimal halbe Minimaldistanz
            {
               print("verschiebung zu gross")
               verschiebung = tempabstandvor-mindistanz
            }
            
  //          print("zeile: \(k) verschiebung nach korr: \(verschiebung)")
         
            for l in 0..<tempclusterarrayzeile.endIndex
            {
               let tempindex:CGFloat = CGFloat(Int(tempclusterarrayzeile[l]["index"] ?? 0))
               let neueposition:CGFloat = (tempclusterarrayzeile[l]["legendeposition"] ?? 0) - verschiebung
               
               let changeindex = legendeindexarray.index(of: tempindex)
//               print("changeindex:\(changeindex)")
               legendedicarray[changeindex ?? 0]["legendeposition"] = neueposition
            }
            
         }// if count
 //        print("*** clusterarray nach: \(clusterarray)")
      }
   }
   
   func setLegendearray_B(legendearray:[[String:CGFloat]])
   
   {
      //legendearray:  dics mit index und wert fuer jeden datenpunkt, geordnet nach groesse
      print("\n\n*****************  setlegendearray start")
      var clusterarray:[[[String:CGFloat]]] = [[[:]]] // arrays von werten mit zu kleinem abstand
      //clusterarray.append([["index":0],["wert":0]])
      // Array mit Dics zu jedem Cluster: Array mit Elementen, abstaende usw,
      
      for legendelinie  in legendearray
      {
         print("index: \(legendelinie["index"] ?? 0) wert: \(legendelinie["wert"] ?? 0) ")
      }
      
      legendedicarray = Array(repeating:["String":0],count:legendearray.count)

      
      var newlegendearray:[[String:CGFloat]] = Array(repeating:["String":0],count:legendearray.count)
      // Abstande einsetzen
      var lastposition:CGFloat = randunten // effektive Position des vorherigen Elements, am Anfang = unterer Rand
      var minposition:CGFloat = randunten     // minimalposition fuer Element
      var distanz:CGFloat = 0     // effektive distanz zum vorherigen Element
      
      var clusterindex:CGFloat = 0
      //legendedicarray.removeAll()
      var abstandmin:CGFloat = 1000
      // abstaende abfragen: minimum suchen
      var minindex:CGFloat = 0
      var mindicO:[String:CGFloat] = legendearray[0]
      var mindicU:[String:CGFloat] = legendearray[0]
      let mindestabstand:CGFloat = mindistanz
      var mitte:CGFloat  = 0; // schwerpunkt des clusters
      var clusterH:CGFloat  = 0; // hoehe des clusters
      var clusterO:CGFloat  = 0; // oberer Rand
      var clusterU:CGFloat  = 0; // unterer Rand
      
      // ordinateclusterarray
      var ordinateclusterarray:[[[String:CGFloat]]] = [[[:]]] // 
      
      var minabstandarray = [[[String:CGFloat]]]()
      
      var clusterindexset = IndexSet()
      newlegendearray[0] = legendearray[0]
      newlegendearray[0]["legendeposition"] = legendearray[0]["wert"] // ohne clusterbildung identisch
      
      legendedicarray[0] = legendearray[0]
      legendedicarray[0]["legendeposition"] = legendearray[0]["wert"] // ohne clusterbildung identisch

      for i in 1..<legendearray.count
      {
         newlegendearray[i] = legendearray[i]
         legendedicarray[i] = legendearray[i]
         legendedicarray[i]["legendeposition"] = legendearray[1]["wert"] // ohne clusterbildung identisch
         if clusterindexset.contains(i)
         {
            break
         }
         
         let last = legendearray[i-1]["wert"] ?? 0.0
         let temp = legendearray[i]["wert"] ?? 0.0
         //print("i: \(i) temp: \(s2(temp))")
         let tempabstand = temp - last
         
         
         if temp - last < mindestabstand // Vorkommen detektiert
         {
            /*
             var clusterdic:[String:CGFloat] = [:]
             clusterdic["legendeposition"] = legendeposition
             clusterdic["clusterindex"] = CGFloat(clusterindex)
             clusterdic["index"] = CGFloat(index)
             clusterdic["wert"] = tempwert
             clusterdic["lastposition"] = lastposition
             clusterdic["abstandvor"] = 0

             */
            var wertsumme:CGFloat = 0 // akkumulierte Hoehe des clusters fuer mittebestimmung
            var tempclusterdicarray = [[[String:CGFloat]]]()  // dics des clusters
            //var clusterdic 
            var anzclusterelemente = 0
            var temppositionU:CGFloat = 0
            var temppositionO:CGFloat = 0
            
            abstandmin = temp - last
            
            mindicO = legendearray[i]  // Ordinate des oberen elements 
            mindicO["clusterindex"] = clusterindex
            
            legendedicarray[i]["clusterindex"] = clusterindex
            newlegendearray[i]["clusterindex"] = clusterindex
            
            mindicU = legendearray[i-1] // Ordinate des unteren elements 
            mindicU["clusterindex"] = clusterindex
            
            
            
            anzclusterelemente += 2
            
            // wertsumme:
            wertsumme = mindicO["wert"]! + mindicU["wert"]!
            mitte = (mindicO["wert"]! + mindicU["wert"]!)/CGFloat(anzclusterelemente) // Schwerpunkt des clusters
   
            temppositionO = mitte + mindistanz/2        // legendeposition startelement
            mindicO["legendeposition"] = temppositionO 
            tempclusterdicarray.append([mindicO])
            legendedicarray[i]["legendeposition"] = temppositionO 
            
            
            temppositionU = mitte - mindistanz/2 // legendeposition in legende unteres Element
            mindicU["legendeposition"] = temppositionU
            tempclusterdicarray.append([mindicU])
            legendedicarray[i-1] = mindicU
            //mitte = (mindicO["wert"]! + mindicU["wert"]!)/2
            
            clusterH = 2*mindistanz // Paket mit 2 Feldern
            clusterO = mitte + mindistanz // aktueller oberer Rand
            clusterU = mitte - mindistanz // aktueller unterer Rand, 
            
            
           // minindex = legendearray[i]["index"] ?? 0
           // var tempabstanddic:[[String:CGFloat]] = [["index": minindex],["abstand":temp - last]]
            clusterindexset.insert(i)
            clusterindexset.insert(i-1)
    
            
            // groessere werte checken
            var k = i+1 // next position
            while k <  legendearray.count
            {
               let tempwert = legendearray[k]["wert"] ?? 0 // wert des El
               let tempindex = legendearray[k]["index"] ?? 0 // index des El
               
               if tempwert < clusterO + mindistanz // wert wuerde cluster tangieren
               {
                  if !clusterindexset.contains(k)
                  {
                     print("i: \(i) k: \(k) weiteres Element gefunden oben")
                     wertsumme += tempwert
                     anzclusterelemente += 1
        //             mitte = (mindicO["wert"]! + mindicU["wert"]! + tempwert) / CGFloat(anzclusterelemente)
                     
                     var templegendeelement = legendearray[k]
                     
                     let tempindex = legendearray[k]["index"] ?? 0
                     templegendeelement["clusterindex"] = clusterindex
                     temppositionO += mindistanz // ein schritt hoeher
                     templegendeelement["legendeposition"] = temppositionO
                     
                     // element einsetzen
                     tempclusterdicarray.append([templegendeelement])
                     legendedicarray[k] = templegendeelement
                     clusterindexset.insert(k)
                     clusterO += mindistanz // cluster reicht hoeher
                     clusterH += mindistanz
                  }
               }
               
  //             minabstandarray.append(tempabstanddic)
               k += 1
            }// while k
            
            // kleinere Werte checken
            var m = i-2 // prev position, i-1 ist bereits gechecked
            while m > 0
            {
               let tempwert = legendearray[m]["wert"] ?? 0
               if tempwert > clusterU - mindistanz // schrift von wert wuerde cluster tangieren
               {
                  if !clusterindexset.contains(m)
                  {
                     print("i: \(i) m: \(m) weiteres Element gefunden unten")
                     wertsumme += tempwert
                     anzclusterelemente += 1
                     var templegendeelement = legendearray[m]
                     let tempindex = legendearray[m]["index"] ?? 0
                     templegendeelement["clusterindex"] = clusterindex
                     temppositionU -= mindistanz // ein schritt tiefer
                     templegendeelement["legendeposition"] = temppositionU
                     
                     // element einsetzen
                     tempclusterdicarray.append([templegendeelement])
                     legendedicarray[m] = templegendeelement
                     clusterindexset.insert(m)
                     clusterU -= mindistanz // cluster reicht tiefer
                     clusterH += mindistanz
                  }
               }
               m -= 1
            } // while m
            
            print("\ni: \(i)\t clusterO: \t\(s2(clusterO)) \tclusterU: \t\(s2(clusterU))  \tclusterH: \t\(s2(clusterH)) mitte: \t\(s2(mitte))")

           //  \(tempclusterdicarray)  clusterindex:\(clusterindex) clusterO: \(s2(clusterO))  clusterU: \(s2(clusterU))")
            
            print("tempclusterdicarray:")
            for clusterzeile in tempclusterdicarray
            {
               let lp = clusterzeile[0]["legendeposition"] ?? 0
               print("zeile wert: \t\(String(format:"%2.2f",clusterzeile[0]["wert"] ?? 0)) \tindex: \t\(s2(clusterzeile[0]["index"] ?? 0)) \tlegendeposition: \t\(s2(lp)) \tclusterindex: \t\(s2(clusterzeile[0]["clusterindex"] ?? 0))")
               
               //print(clusterzeile)
            }
            
            
            //tempclusterdicarray sortieren
            let newmitte = wertsumme / CGFloat(anzclusterelemente)
            let verschiebung = mitte - (wertsumme / CGFloat(anzclusterelemente))
            
            print("i: \(i) clusterindex: \(clusterindex) i: \(i) wertsumme: \(s2(wertsumme)) mitte: \(s2(mitte)) newmitte: \(s2(newmitte)) clusterU: \(s2(clusterU)) verschiebung: \(s2(verschiebung))")
            
            
            m = i-2 // Werte vor i, rueckwaerts
            while (m > 0)
            {
               let tempwert = legendearray[m]["wert"] ?? 0
               
               let distanz = clusterU - tempwert  // distanz zu unterem Rand des Clusters
               print("i: \(i) m: \(m) distanz: \(s2(distanz))")
               if distanz <  mindistanz/2 // wert wuerde cluster tangieren
               {
                  print("Element zu nahe")
               }
               m -= 1
            }
            
            
            print("***  i: \(i) anz cluster: \(tempclusterdicarray.count)")

            print("********** end if < mindestabstand \n")
            
            clusterindex += 1
         } // if < mindestabstand
 
         //print("*** end for i clusterindexset count: \(clusterindexset.count) clusterindexset: \(clusterindexset)")
 
      } // for i .. legendearray count
      
      
      
      
      /*
      print("\nminabstandarray:")
      for zeile in minabstandarray
      {
         print(zeile)
      }
      print("minabstandarray: \(minabstandarray)")
      
      print("\n")
     */
      
      print("\n newlegendearray nach ")
       for i in 0..<legendedicarray.count
      {
         print("i: \(i) zeile:\(legendedicarray[i])")
        }
      print("\n")
      print("\n legendearray nach ")
       for i in 0..<legendearray.count
      {
         
         print("i: \(i) legendearray: \(legendearray[i])")
         let indexzeile:[String:CGFloat] = legendearray[i]
         let index = indexzeile["index"]
         let tempwert:CGFloat = indexzeile["wert"] ?? 0 // wert, y-Abstand
         
         
         
         return
         
         
         // wenn genuegend Platz: Legende neben wert
         var legendeposition:CGFloat  = tempwert // lage neben graphlinie
        
         if tempwert < minposition // 
         {
            legendeposition = minposition  // legende wird auf minpos angehoben
            
            if i > 0 // nicht unterste position
            {
               //print("clusterarray.last: \(clusterarray.last) count: \(clusterarray.last?.count)")
               if clusterarray.last?.count == 1 // Array noch leer, objekt einfuegen
               {
                  //print("leer")
                  var prevclusterdic:[String:CGFloat] = legendearray.last ?? ["":0]// ?? ["clusterindex":0]
                  let l = legendearray.last
                  
                  prevclusterdic["clusterindex"] = clusterindex
                  let endpos = clusterarray.endIndex
                  //print("last: \(l)")
                  clusterarray[endpos-1].append(prevclusterdic)
               
               }
               let anz = clusterarray.endIndex
               var clusterdic:[String:CGFloat] = [:]
               clusterdic["legendeposition"] = legendeposition
               clusterdic["clusterindex"] = clusterindex
               clusterdic["index"] = index
               clusterdic["wert"] = tempwert
               clusterdic["lastposition"] = lastposition
               clusterdic["abstandvor"] = 0
               clusterarray[anz-1].append(clusterdic)
               
            }
            else // erstes Element
            {
            }
            
            
         }// tempwert < minposition
         else // abstand ausreichend, incl randunten beim ersten Objekt
         {
            minposition = tempwert
            // Cluster fertig, neuen Array fuer eventuellen naechsten Cluster anfuegen
            let lastobjcount:Int = clusterarray.last?.count ?? 0
            if lastobjcount > 0 // der letzte Cluster hatte Elemente
            {
               var lastlegendeposition:CGFloat = 0
               let last:[[String : CGFloat]] = clusterarray.last ?? [["":0]]
               let lastindex = last.count
               if lastindex > 0
               {
                  
                  let lastlast:[String : CGFloat] = last[lastindex-1]
                  let lastlastindex = lastlast.count
                  
                  
                  if lastlastindex > 0
                  {
                     lastlegendeposition = lastlast["legendeposition"] ?? 0
                     //clusterarray[lastindex-1][0]["abstandnach"] = CGFloat(legendeposition-(lastlegendeposition ))

                  }
                  

               }  
               let newlegendeposition:CGFloat = legendeposition-(lastlegendeposition ?? 0) 
               
               //clusterarray[lastindex][0]["abstandnach"] = CGFloat(legendeposition-lastlegendeposition)
               
     //          clusterarray[lastindex-1][lastlastindex-1]["abstandnach"] = CGFloat(legendeposition-(lastlegendeposition ?? 0))
              // clusterarray.append([[ : ]])
               clusterindex += 1
            } // der letzte Cluster hatte Elemente
         }
         distanz = legendeposition-distanz
          
         var legendedic:[String:CGFloat] = [:]
         legendedic["legendeposition"] = legendeposition
         legendedic["clusterindex"] = clusterindex
         legendedic["index"] = index
         legendedic["wert"] = tempwert
         legendedic["lastposition"] = lastposition
         legendedic["abstandvor"] = distanz
         legendedicarray.append(legendedic)
         
         lastposition = legendeposition
         minposition += mindistanz
         

      }// for legendearray.count
//      print("*** clusterarray vor: \(clusterarray)")
      
      //let i = legendedicarray[0]["index"]
      var legendeindexarray:[CGFloat] = []
      legendeindexarray.removeAll()
     
      
      for line in legendedicarray
      {
 //        print("legendedicarray line: \(line)")
         legendeindexarray.append(line["index"] ?? 0)
      }
//      print("legendeindexarray: \(legendeindexarray)")      
      
      for k in 0..<clusterarray.endIndex
      {
 //        print("k: \(k)")
         /*
         for l in 0..<clusterarray[k].endIndex
         {
         print("l: \(l) data: \(clusterarray[k][l])")
         }
         */
         var verschiebung:CGFloat  = 0
         var tempclusterarrayzeile = clusterarray[k]
         
         if tempclusterarrayzeile.count > 0
         {
            var tempabstandvor:CGFloat  = tempclusterarrayzeile[0]["abstandvor"] ?? abstandvor
         
            // Differenz zwischen legendeposition und wert des obersten Elements minus gleiche Differnz des untersten Elements ergibt doppelte Verschiebung
            let lastlegendeposition = tempclusterarrayzeile.last?["legendeposition"] ?? 0
            let startlegendeposition = tempclusterarrayzeile[0]["legendeposition"] ?? 0
            verschiebung = lastlegendeposition - startlegendeposition
            
            verschiebung /= 2
 //           print("zeile \(k) verschiebung: \(verschiebung) tempabstandvor: \(tempabstandvor) mindistanz: \(mindistanz)")
            if verschiebung > tempabstandvor - mindistanz // Verschiebung abzueglich zweimal halbe Minimaldistanz
            {
               print("verschiebung zu gross")
               verschiebung = tempabstandvor-mindistanz
            }
            
  //          print("zeile: \(k) verschiebung nach korr: \(verschiebung)")
         
            for l in 0..<tempclusterarrayzeile.endIndex
            {
               let tempindex:CGFloat = CGFloat(Int(tempclusterarrayzeile[l]["index"] ?? 0))
               let neueposition:CGFloat = (tempclusterarrayzeile[l]["legendeposition"] ?? 0) - verschiebung
               
               let changeindex = legendeindexarray.index(of: tempindex)
//               print("changeindex:\(changeindex)")
               legendedicarray[changeindex ?? 0]["legendeposition"] = neueposition
            }
            
         }// if count
 //        print("*** clusterarray nach: \(clusterarray)")
      }
   }
   func setLegendearray_old(legendearray:[[String:CGFloat]])
   {
      //legendearray:  dics mit index und wert fuer jeden datenpunkt, geordnet nach groesse
      print("*****************  setlegendearray start")
      var clusterarray:[[[String:CGFloat]]] = [[[:]]]
      //clusterarray.append([["index":0],["wert":0]])
      // Array mit Dics zu jedem Cluster: Array mit Elementen, abstaende usw,
      
      // Abstande einsetzen
      var lastposition:CGFloat = randunten // effektive Position des vorherigen Elements, am Anfang = unterer Rand
      var minposition:CGFloat = randunten     // minimalposition fuer Element
      var distanz:CGFloat = 0     // effektive distanz zum vorherigen Element
      
      
      var clusterindex:CGFloat = 0
      legendedicarray.removeAll()
      for i in 0..<legendearray.count
      {
         let indexzeile:[String:CGFloat] = legendearray[i]
         let index = indexzeile["index"]
         let tempwert:CGFloat = indexzeile["wert"] ?? 0 // wert, y-Abstand
         
         // wenn genuegend Platz: Legende neben wert
         var legendeposition:CGFloat  = tempwert // lage neben graphlinie
        
         if tempwert < minposition // 
         {
            legendeposition = minposition  // legende wird auf minpos angehoben
            
            if i > 0 // nicht unterste position
            {
               print("clusterarray.last: \(clusterarray.last) count: \(clusterarray.last?.count)")
               if clusterarray.last?.count == 1 // Array noch leer, objekt einfuegen
               {
                  print("leer")
                  var prevclusterdic:[String:CGFloat] = legendearray.last ?? ["":0]// ?? ["clusterindex":0]
                  let l = legendearray.last
                  
                  prevclusterdic["clusterindex"] = clusterindex
                  let endpos = clusterarray.endIndex
                  print("last: \(l)")
                  clusterarray[endpos-1].append(prevclusterdic)
               
               }
               let anz = clusterarray.endIndex
               var clusterdic:[String:CGFloat] = [:]
               clusterdic["legendeposition"] = legendeposition
               clusterdic["clusterindex"] = clusterindex
               clusterdic["index"] = index
               clusterdic["wert"] = tempwert
               clusterdic["lastposition"] = lastposition
               clusterdic["abstandvor"] = 0
               clusterarray[anz-1].append(clusterdic)
               
            }
            else // erstes Element
            {
            }
            
            
         }// tempwert < minposition
         else // abstand ausreichend, incl randunten beim ersten Objekt
         {
            minposition = tempwert
            // Cluster fertig, neuen Array fuer eventuellen naechsten Cluster anfuegen
            let lastobjcount:Int = clusterarray.last?.count ?? 0
            if lastobjcount > 0 // der letzte Cluster hatte Elemente
            {
               var lastlegendeposition:CGFloat = 0
               let last:[[String : CGFloat]] = clusterarray.last ?? [["":0]]
               let lastindex = last.count
               if lastindex > 0
               {
                  
                  let lastlast:[String : CGFloat] = last[lastindex-1]
                  let lastlastindex = lastlast.count
                  
                  
                  if lastlastindex > 0
                  {
                     lastlegendeposition = lastlast["legendeposition"] ?? 0
                     //clusterarray[lastindex-1][0]["abstandnach"] = CGFloat(legendeposition-(lastlegendeposition ))

                  }
                  

               }  
               let newlegendeposition:CGFloat = legendeposition-(lastlegendeposition ?? 0) 
               
               //clusterarray[lastindex][0]["abstandnach"] = CGFloat(legendeposition-lastlegendeposition)
               
     //          clusterarray[lastindex-1][lastlastindex-1]["abstandnach"] = CGFloat(legendeposition-(lastlegendeposition ?? 0))
              // clusterarray.append([[ : ]])
               clusterindex += 1
            } // der letzte Cluster hatte Elemente
         }
         distanz = legendeposition-distanz
          
         var legendedic:[String:CGFloat] = [:]
         legendedic["legendeposition"] = legendeposition
         legendedic["clusterindex"] = clusterindex
         legendedic["index"] = index
         legendedic["wert"] = tempwert
         legendedic["lastposition"] = lastposition
         legendedic["abstandvor"] = distanz
         legendedicarray.append(legendedic)
         
         lastposition = legendeposition
         minposition += mindistanz
         

      }// for legendearray.count
      print("*** clusterarray vor: \(clusterarray)")
      
      //let i = legendedicarray[0]["index"]
      var legendeindexarray:[CGFloat] = []
      legendeindexarray.removeAll()
     
      
      for line in legendedicarray
      {
         print("legendedicarray line: \(line)")
         legendeindexarray.append(line["index"] ?? 0)
      }
      print("legendeindexarray: \(legendeindexarray)")      
      
      for k in 0..<clusterarray.endIndex
      {
         print("k: \(k)")
         /*
         for l in 0..<clusterarray[k].endIndex
         {
         print("l: \(l) data: \(clusterarray[k][l])")
         }
         */
         var verschiebung:CGFloat  = 0
         var tempclusterarrayzeile = clusterarray[k]
         
         if tempclusterarrayzeile.count > 0
         {
            var tempabstandvor:CGFloat  = tempclusterarrayzeile[0]["abstandvor"] ?? abstandvor
         
            // Differenz zwischen legendeposition und wert des obersten Elements minus gleiche Differnz des untersten Elements ergibt doppelte Verschiebung
            let lastlegendeposition = tempclusterarrayzeile.last?["legendeposition"] ?? 0
            let startlegendeposition = tempclusterarrayzeile[0]["legendeposition"] ?? 0
            verschiebung = lastlegendeposition - startlegendeposition
            
            verschiebung /= 2
            print("zeile \(k) verschiebung: \(verschiebung) tempabstandvor: \(tempabstandvor) mindistanz: \(mindistanz)")
            if verschiebung > tempabstandvor - mindistanz // Verschiebung abzueglich zweimal halbe Minimaldistanz
            {
               print("verschiebung zu gross")
               verschiebung = tempabstandvor-mindistanz
            }
            
            print("zeile: \(k) verschiebung nach korr: \(verschiebung)")
         
            for l in 0..<tempclusterarrayzeile.endIndex
            {
               let tempindex:CGFloat = CGFloat(Int(tempclusterarrayzeile[l]["index"] ?? 0))
               let neueposition:CGFloat = (tempclusterarrayzeile[l]["legendeposition"] ?? 0) - verschiebung
               
               let changeindex = legendeindexarray.index(of: tempindex)
//               print("changeindex:\(changeindex)")
               legendedicarray[changeindex ?? 0]["legendeposition"] = neueposition
            }
            
         }// if count
         print("*** clusterarray nach: \(clusterarray)")
      }
   } // end setLegendearray
   
   
   
}// end rDatenlegende
