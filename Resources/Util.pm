package Resources::Util;

use Nemesis::BaseRes -base;

##Manual match (for legacy purposes we can't use smartmatch) for array

sub match() {
    my $array = shift;
    my $value = shift;
    my %hash = map { $_ => 1 } @$array;
    $hash{$value} ? return 1 : return 0;
}

!!42;
