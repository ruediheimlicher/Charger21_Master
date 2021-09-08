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
   var    randunten:CGFloat = 12, randoben:CGFloat = 0, abstandnach:CGFloat = -1, abstandvor:CGFloat = -1, mindistanz:CGFloat = 12;
   var legendedicarray:[String:CGFloat] = [:]
   
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
   
   func setLegendearray(legendearray:[[String:CGFloat]])
   {
      //legendearray:  dics mit index und wert fuer jeden datenpunkt, geordnet nach groesse
      
      var clusterarray:[[[String:CGFloat]]] = [[[:]]]
      // Array mit Dics zu jedem Cluster: Array mit Elementen, abstaende usw,
      
      // Abstande einsetzen
      var lastposition:CGFloat = randunten // effektive Position des vorherigen Elements, am Anfang = unterer Rand
      var minposition:CGFloat = randunten     // minimalposition fuer Element
      var distanz:CGFloat = 0     // effektive distanz zum vorherigen Element
      
      
      var clusterindex:CGFloat = 0
      
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
               if clusterarray.last?.count == 0 // Array noch leer, objekt einfuegen
               {
                  print("leer")
                  var prevclusterdic:[String:CGFloat] = legendearray.last ?? ["clusterindex":0]
                  let l = legendearray.last
                  prevclusterdic["clusterindex"] = clusterindex
                  print("last: \(l)")
               //   clusterarray.last.append(prevclusterdic)
               }
            }
         }// tempwert < minposition
      }// for legendedicarray.count
   } // end setLegendearray
   
   
   
}// end rDatenlegende
