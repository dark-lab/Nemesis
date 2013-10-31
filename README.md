Nemesis
=======
Nemesis is a FOSS (Free and Open Source Software) framework for network pen-testing<br />

This framework's objective is to help any pen-testers in their job improving the user experience of the various tools.<br /> <br />

## Description
Nemesis is a framework enterely wirtten in Perl, structured for create an environment Pen-Testers friendly.
The framework links informations gathered from different tools and facilitates the execution of some attack's vectors.
The software is modular ad thought to be extended from anyone whants to add/improve features of the program.
Users can execute stuff from a simple CLI, with a debug mode for developers, that is really easy to use.


### Goals:

* Create a unique interface to pen-testing's progrms;
* Link informations found from different tools;
* Automate standard operation and common routine during pen-testing;
* LAN/WLAN Exploiting;
* Web App Exploiting;
* Make pen-testing fun!

## The Complex Stuff:
+ Tox must use UDP simply because [hole punching](http://en.wikipedia.org/wiki/UDP_hole_punching) with TCP is not as reliable.
+ Every peer is represented as a [byte string][String] (the public key of the peer [client ID]).
+ We're using torrent-style DHT so that peers can find the IP of the other peers when they have their ID.
+ Once the client has the IP of that peer, they start initiating a secure connection with each other. (See 
[Crypto](https://github.com/irungentoo/ProjectTox-Core/wiki/Crypto))
+ When both peers are securely connected, they can exchange messages, initiate a video chat, send files, etc, all using encrypted communications.
+ Current build status: [![Build Status](https://travis-ci.org/irungentoo/ProjectTox-Core.png?branch=master)](https://travis-ci.org/irungentoo/ProjectTox-Core)


### Why are you doing this? There are already a bunch of free skype alternatives.
The goal of this project is to create a configuration-free P2P skype 
replacement. Configuration-free means that the user will simply have to open the program and 
without any account configuration will be capable of adding people to his 
friends list and start conversing with them. There are many so-called skype replacements and all of them are either hard to 
configure for the normal user or suffer from being way too centralized.

## TODO:
- [TODO](/TODO)
 
**Dependencies**
Alt::Crypt::RSA::BigInt<br />
App::FatPacker<br />
Crypt::CBC<br />
Data::MessagePack<br />
Data::Structure::Util<br />
DateTime<br />
Devel::Declare::Lexer<br />
Devel::Declare::Lexer::Factory<br />
Getopt::Long<br />
HTTP::Request<br />
KiokuDB<br />
KiokuDB::Util<br />
LWP<br />
LWP::Simple<br />
Module::Loaded<br />
Mojo::IOLoop<br />
Mojo::Server::Daemon<br />
Mojolicious::Lite<br />
Moose<br />
Moose::Util::TypeConstraints<br />
MooseX::Declare<br />
Net::Frame::Dump::Online<br />
Net::Frame::Layer::DNS<br />
Net::Frame::Layer::DNS::RR<br />
Net::Frame::Layer::ETH<br />
Net::Frame::Layer::IPv4<br />
Net::Frame::Layer::UDP<br />
Net::Frame::Simple<br />
Net::IP<br />
Net::Write::Layer<br />
Net::Write::Layer2<br />
NetAddr::IP<br />
Nmap::Parser<br />
POE<br />
Regexp::Common<br />
Scalar::Util<br />
Search::GIN::Extract::Class<br />
Search::GIN::Query::Class<br />
Search::GIN::Query::Manual<br />
Term::ANSIColor<br />
Term::UI<br />
Term::Visual<br />
Unix::PID<br />
WWW::Mechanize<br />
forks<br />
namespace::autoclean<br />
All programs useful for pen-testing<br />
And obviously Perl!

**How install Nemesis**
The fastest way to get Nemesis full working on your war PC is to run:<br />
  cpanm --installdeps .
This will install all dependencies required by Nemesis in your PC.

## Suggestions
Extensibility is the most important feature of this framework. 
So we are very happy to get some feedbacks from comunity, if you have some useful suggestions about the project don't wait to submit them to us!
