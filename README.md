Nemesis
=======
Nemesis is a FOSS (Free and Open Source Software) framework for network pen-testing


This framework's aim to help any pen-testers in their job improving the user experience of the various tools.<br /> <br />

## Description
Nemesis is a framework enterely written in Perl, structured to make a friendly environment for Pen-Testers.
The framework links informations gathered from different tools and facilitates the execution of some attack's vectors.
The software is modular and can be extended from anyone who wants, just make a pull!
Every module can be loaded and unloaded in runtime just to suite the occasion of use (one of the goals is to run on an embedded system).
Users can execute stuff from a simple CLI, with a debug mode for developers and is really easy to use.


### Goals:

* Create a unique interface to pen-testing's programs;
* Link informations found from different tools;
* Automate standard operation and common routine during pen-testing;
* LAN/WLAN Exploiting;
* Web App Exploiting;
* Make pen-testing fun!

## The Complex Stuff:
* Finalizing the metasploit integration
* Rewriting of the modules to be more tiny for most environment, to delete the ```minimal``` branch
* Give it a code clean and maybe a MakeFile.PL
* maybe writing a better TODO and a fixed milestone? just adding stuff to todo it's making all more difficult

## TODO:
- [TODO](/TODO)
 


Module that are capable to load will load, so minimal functions it's garanted (for execution as a daemon).


**Minimal Dependencies**



**Full Dependencies**
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
