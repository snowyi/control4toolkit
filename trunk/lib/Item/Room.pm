#!/usr/bin/perl

package Room;

#use strict;
#use C4Toolkit;

sub new 
{
    my $class = shift;
    my $self = {
	_name => shift,
	_id => shift,
	_lights => shift,
    };
    
    bless $self, $class;
    return $self;
}

sub getID {
    my( $self ) = @_;
    return $self->{_id};
}

sub getName 
{
    my( $self ) = @_;
    return $self->{_name};
}

sub getLights {
    my( $self ) = @_;
    #print "getLights() returning $self->{_lights}\n";
    return $self->{_lights};
}

sub addLight {
    my( $self ) = @_;
    shift;
    my $tempLightID = shift;

#    print "given templightid $tempLightID for room $self->{_id}\n";

    my $prevLights_ref = $self->{_lights};
    my @prevLights = @$prevLights_ref;


    $prevLights[$#prevLights + 1] = $tempLightID;
    $self->{_lights} = \@prevLights;


}
1;
