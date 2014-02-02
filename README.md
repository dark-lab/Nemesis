Nemesis
=======

<pre>
                                                                                       
                                                                                           
  L.                      ,;                                ,;           .                .
  EW:        ,ft        f#i                               f#i           ;W  t            ;W
  E##;       t#E      .E#t              ..       :      .E#t           f#E  Ej          f#E
  E###t      t#E     i#W,              ,W,     .Et     i#W,          .E#f   E#,       .E#f 
  E#fE#f     t#E    L#D.              t##,    ,W#t    L#D.          iWW;    E#t      iWW;  
  E#t D#G    t#E  :K#Wfff;           L###,   j###t  :K#Wfff;       L##Lffi  E#t     L##Lffi
  E#t  f#E.  t#E  i##WLLLLt        .E#j##,  G#fE#t  i##WLLLLt     tLLG##L   E#t    tLLG##L 
  E#t   t#K: t#E   .E#L           ;WW; ##,:K#i E#t   .E#L           ,W#i    E#t      ,W#i  
  E#t    ;#W,t#E     f#E:        j#E.  ##f#W,  E#t     f#E:        j#E.     E#t     j#E.   
  E#t     :K#D#E      ,WW;     .D#L    ###K:   E#t      ,WW;     .D#j       E#t   .D#j     
  E#t      .E##E       .D#;   :K#t     ##D.    E#t       .D#;   ,WK,        E#t  ,WK,      
  ..         G#E         tt   ...      #G      ..          tt   EG.         E#t  EG.       
              fE                       j                        ,           ,;.  ,         
               ,                                                

                            dHP^~"        "~^THb.
                          .AHF                YHA.  
                         .AHHb.              .dHHA.  
                         HHAUAAHAbn      adAHAAUAHA  
                         HF~"_____        ____ ]HHH 
                         HAPK""~^YUHb  dAHHHHHHHHHH
                         HHHD> .andHH  HHUUP^~YHHHH
                         ]HHP     "~Y  P~"     THH[ 
                         `HK                   ]HH'  
                          THAn.  .d.aAAn.b.  .dHHP
                          ]HHHHAAUP" ~~ "YUAAHHHH[
                          `HHP^~"  .annn.  "~^YHH'
                           YHb    ~" "" "~    dHF
                            "YAb..abdHHbndbndAP"
                              THHAAb.  .adAHHF
                              "UHHHHHHHHHHU"     
                                ]HHUUHHHHHH[
                              .adHHb "HHHHHbn.
                       ..andAAHHHHHHb.AHHHHHHHAAbnn..
                  .ndAAHHHHHHUUHHHHHHHHHHUP^~"~^YUHHHAAbn.
                    "~^YUHHP"   "~^YUHHUP"        "^YUP^"
                         ""         "~~"

</pre>


Nemesis is a FOSS (Free and Open Source Software) framework for network pen-testing


This framework's aim to help any pen-testers in their job improving the user experience of the various tools.


## Description
Nemesis is a framework enterely written in Perl, structured to make a friendly environment for Pen-Testers.
The framework links informations gathered from different tools and facilitates the execution of some attack's vectors.
The software is modular and can be extended from anyone who wants, just make a pull!
Every module can be loaded and unloaded in runtime just to fit your needs (one of the goals is to run on an embedded system).
Users can execute stuff from a simple CLI, with a debug mode for developers and is really easy to use.
The CLI is structured to have a simple workflow for your pentesting sessions.

## Status
Currently it's under developing, so there are basic functionality working for now
CI Status (master branch): [![Build Status](https://travis-ci.org/dark-lab/Nemesis.png?branch=master)](https://travis-ci.org/dark-lab/Nemesis)

### Goals:

* Create a unique interface to pen-testing's programs;
* Link informations found from different tools;
* Automate standard operation and common routine during pen-testing;
* Making metasploit usage automatized
* Leveraging metasploit exploit database to analyze active/passive traffic to match exploits fingerprintings (mostly done)
* LAN/WLAN Exploiting (We are almost at the end of this);
* Web App Exploiting;
* Make pen-testing fun!

## The Complex Stuff:
* Finalizing the metasploit integration
* Module rewrital, to be more portable for most environment, we need to delete the ```minimal``` branch
* We need to clean the code and maybe a MakeFile.PL (I know, PM maybe will hate us)
* maybe writing a better TODO and a fixed milestone? just adding stuff to todo it's making all more difficult

## TODO:
- [TODO](/TODO)
 


Module that are capable to load will load, so minimal functions it's garanted (for execution as a daemon).


**How install Nemesis**

You typically dont' need to install it unless you want some other juicy features.
If you need the full interface, the fastest way to get Nemesis full working on your war PC is to run:

```cpanm --installdeps .```

This will automatically install all dependencies required.
***
If you don't need all that stuff, you can run *nemesis* as a daemon, but you will loose the CLI workflow, you can achieve that by setting up a session (works like a scripting interface) that can be read from the software and will execute the tasks you need

## Suggestions
Extensibility is the most important feature of this framework. 
So we are very happy to get some feedbacks from comunity, if you have some useful suggestions about the project don't wait to submit them to us! Pull Requests and issues are welcome!


***

##Why do we need another framework for pentesting, metasploit it's not enough?

Yes, i think it's enough. This is a personal project that we made to automize tasks because we wanna to export metasploit functionality in an embedded system: our goal here it's to build a device capable to exploit LAN and WLAN so the pentester can be more hidden (thus nobody can have suspects on you  ;)  ).

Our dream it's to import metasploit exploits, and execute them in the framework: why? we wanna be an alternative to funcy ruby stuff.

***

Feel free to contact us! 
mudler@dark-lab.net skullbocks@dark-lab.net


## License
    Nemesis - Pentesting Framework
    Copyright (C) 2013  mudler@dark-lab.net, skullbocks@dark-lab.net

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
