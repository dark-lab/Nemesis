package Nemesis::Base; #it's Object::Simple

 
our $VERSION = '3.09';
 
use strict;
use warnings;
no warnings 'redefine';
 
use Carp ();
 
sub import {
  my ($class, @methods) = @_;
 
  # Caller
  my $caller = caller;
   
  # Base
  if ((my $flag = $methods[0] || '') eq '-base') {
 
    # Can haz?
    no strict 'refs';
    no warnings 'redefine';
    *{"${caller}::has"} = sub { attr($caller, @_) };
     
    # Inheritance
    if (my $module = $methods[1]) {
      $module =~ s/::|'/\//g;
      require "$module.pm" unless $module->can('new');
      push @{"${caller}::ISA"}, $module;
    }
    else { push @{"${caller}::ISA"}, $class }
 
    # strict!
    strict->import;
    warnings->import;
 
    # Modern!
    feature->import(':5.10') if $] >= 5.010;
  }
  # Method export
  else {
   
    # Exports
    my %exports = map { $_ => 1 } qw/new attr class_attr dual_attr/;
     
    # Export methods
    for my $method (@methods) {
       
      # Can be Exported?
      Carp::croak("Cannot export '$method'.")
        unless $exports{$method};
       
      # Export
      no strict 'refs';
      *{"${caller}::$method"} = \&{"$method"};
    }
  }
}
 
sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}
 
sub attr {
  my ($self, @args) = @_;
   
  my $class = ref $self || $self;
   
  # Fix argument
  unshift @args, (shift @args, undef) if @args % 2;
   
  for (my $i = 0; $i < @args; $i += 2) {
       
    # Attribute name
    my $attrs = $args[$i];
    $attrs = [$attrs] unless ref $attrs eq 'ARRAY';
     
    # Default
    my $default = $args[$i + 1];
     
    for my $attr (@$attrs) {
 
      Carp::croak qq{Attribute "$attr" invalid} unless $attr =~ /^[a-zA-Z_]\w*$/;
 
      # Header (check arguments)
      my $code = "*{${class}::$attr} = sub {\n  if (\@_ == 1) {\n";
 
      # No default value (return value)
      unless (defined $default) { $code .= "    return \$_[0]{'$attr'};" }
 
      # Default value
      else {
 
        Carp::croak "Default has to be a code reference or constant value (${class}::$attr)"
          if ref $default && ref $default ne 'CODE';
 
        # Return value
        $code .= "    return \$_[0]{'$attr'} if exists \$_[0]{'$attr'};\n";
 
        # Return default value
        $code .= "    return \$_[0]{'$attr'} = ";
        $code .= ref $default eq 'CODE' ? '$default->($_[0]);' : '$default;';
      }
 
      # Store value
      $code .= "\n  }\n  \$_[0]{'$attr'} = \$_[1];\n";
 
      # Footer (return invocant)
      $code .= "  \$_[0];\n}";
 
      # We compile custom attribute code for speed
      no strict 'refs';
      warn "-- Attribute $attr in $class\n$code\n\n" if $ENV{NEMESIS_BASE_DEBUG};
      Carp::croak "Nemesis::Base error: $@" unless eval "$code;1";
    }
  }
}