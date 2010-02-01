#!/usr/bin/perl

package Light;

#use strict;
#use C4Toolkit;

sub new 
{
    my $class = shift;
    my $self = {
	_name => shift,
	_id => shift,
	_dims => shift,
    };
    bless $self, $class;
    return $self;
}

sub getName {
    my( $self ) = @_;
    return $self->{_name};
}

sub getID {
    my( $self ) = @_;
    return $self->{_id};
}

sub getDims {
    my( $self ) = @_;
    return $self->{_dims};
}
1;
