package SpeakerPoint::Interface;
use strict;
use C4Toolkit;
use SpeakerPoint::AudioControl;
my %if_sockets;

sub listen {
	dbg("Opening TCP Interface port");

	# TCP OTHER Control port
	my $Interface = new IO::Socket::INET(
	        Listen    => 1,
	        LocalPort => 5100,
	        Reuse     => 1
	); # TODO: Error-control

	$if_sockets{$Interface} = 'listen';

	return $Interface;
}

sub checkSocket {
	my $Handle = shift;

	if (exists $if_sockets{$Handle}) {
		if ($if_sockets{$Handle} eq 'listen') {
			my $new = $Handle->accept;
			$if_sockets{$new} = 'data';
			dbg("Got a new TCP (interface) connection!");
			return $new;
		}
		elsif ($if_sockets{$Handle} eq 'data') {
			return readPacket($Handle);
		}
	}
} 


sub readPacket {
	my $Handle = shift;
	$_ = <$Handle>;
	if (!defined $_ || $_ eq '') {
		dbg("TCP Client (interface) disconnected");
		return -1;
	}
	
	s/[\n\r]//sgi;
	if (/^([a-f0-9]+)i([a-f0-9]+) (.+)/) {
		
		my $rserial = "$1r$2 ";
		my @args = split(/ /,$3);
		my $cmd = shift(@args);
		my $arg = join " ", @args;
		my $feed = "\r\n";

		dbg(" IN: '$cmd' '$arg'");						

		if ($cmd eq 'c4.sp.spping') {
			se($Handle, $rserial.$cmd.$feed);
		}
		elsif ($cmd eq 'c4.sp.d2' && defined $arg) {
			if ($args[0] eq 'mute') {
				if ($args[1] eq 'toggle') {
					if (SpeakerPoint::AudioControl::get_mute()) {
						SpeakerPoint::AudioControl::mute_off();
					} else {
						SpeakerPoint::AudioControl::mute_on();
					}
					se($Handle, $rserial.$cmd." ".$arg.$feed);
				}
				elsif ($args[1] eq 'on') {
					SpeakerPoint::AudioControl::mute_on();
					se($Handle, $rserial.$cmd." ".$arg.$feed);
				}
				elsif ($args[1] eq 'off') {
					SpeakerPoint::AudioControl::mute_off();
					se($Handle, $rserial.$cmd." ".$arg.$feed);
				}
			}
			elsif ($args[0] eq 'volume') {
				if ($args[1] eq 'setlevel') {
					SpeakerPoint::AudioControl::set_volume(hex($args[2]));
					se($Handle, $rserial.$cmd." ".$arg.$feed);
				}
				
			} else {
				dbg("--UNDEFINED--: $cmd $arg");
				se($Handle, $rserial.$cmd." ".$arg.$feed);
			}
		}
		elsif ($cmd eq 'c4.sp.d2get' && defined $arg) {
			if ($arg eq 'localamp') {
				se($Handle, $rserial.$cmd." localamp off".$feed);
			}
			elsif ($arg eq 'mute') {
			
				se($Handle,$rserial
					.$cmd
					." mute "
					. (
						SpeakerPoint::AudioControl::get_mute() ? 
						'on' : 'off'
					)
					.$feed
				);
			}
			elsif ($arg eq 'treble') {	
				#my @treble = Audio::Mixer::get_cval('treble');
				se($Handle,$rserial.$cmd." treble 0e".$feed);
			}
			elsif ($arg eq 'bass') {
				#my @bass = Audio::Mixer::get_cval('bass');
				se($Handle, $rserial.$cmd." bass 0e".$feed);
			}
			elsif ($arg eq 'balance') {
				se($Handle, $rserial.$cmd." balance center 00".$feed);
			}
			elsif ($arg eq 'volume') {	
				my $vol = SpeakerPoint::AudioControl::get_volume();
				se($Handle, $rserial.$cmd." volume ".sprintf("%2X",$vol).$feed);
			}
			else {
				dbg("Error3 getting $cmd $arg\n");
			}
		}
		else {
			dbg("Error2 getting $cmd");
		}
	}
}


1;
