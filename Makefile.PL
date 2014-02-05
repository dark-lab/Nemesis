#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Nemesis',
    VERSION_FROM => 'lib/Nemesis.pm',
    DISTNAME     => 'Nemesis',
    AUTHOR =>
        'mudler <mudler@dark-lab.net>, skullbocks <skullbocks@dark-lab.net>',
    ABSTRACT =>
        'Nemesis is a pentesting framework and a pentester environment',
    LICENSE => "GPLv3"
);
