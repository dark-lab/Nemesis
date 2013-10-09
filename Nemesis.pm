package Nemesis;

use FindBin '$Bin';
use lib $Bin;
#require forks;
require Nemesis::Init;
require Nemesis::Env;
require Nemesis::Interfaces;
require Nemesis::IO;
require Nemesis::Process;
require Nemesis::Session;
require Nemesis::ModuleLoader;
1;
