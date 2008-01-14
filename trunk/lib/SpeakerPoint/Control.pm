package SpeakerPoint::Control;
use strict;
use C4Toolkit;
use SpeakerPoint::AudioControl;

my %sockets;

sub listen {
	dbg("Opening TCP Control port");

	# TCP Control port
	my $Listen = new IO::Socket::INET(
	        Listen    => 1,
	        LocalPort => 6000,
	        Reuse     => 1
	); # TODO: Error-control

	$sockets{$Listen} = 'listen';

	return $Listen;
}

sub checkSocket {
	my $Handle = shift;

	if (exists $sockets{$Handle}) {
		if ($sockets{$Handle} eq 'listen') {
			my $new = $Handle->accept;
			$sockets{$new} = 'data';
			dbg("Got a new TCP (control) connection!");
			return $new;
		}
		elsif ($sockets{$Handle} eq 'data') {
			return readPacket($Handle);
		}
	}
} 

sub readPacket {
	my $Handle = shift;
	my $Command = <$Handle>;
	if (!defined($Command) || $Command eq '') {
		dbg("TCP Client (control) disconnected");
		return -1;
	}

	$Command =~ s/[\n\r]//sgi;

	if ($Command =~ /^(\d+) (.+)/) {

		my $serial = $1;
		my $cmd = $2;

		dbg("Got command $Command");

		if ($cmd =~ /reset/i) {
			dbg("Reseting");
			se($Handle, "$serial OK reset");
		}

		elsif ($cmd =~ /^setmut (\d+) (off|on)/i) {
			se($Handle, "$serial OK SETMUT");

			if (lc($2) eq 'on') {
				SpeakerPoint::AudioControl::mute_on();
			}
			elsif (lc($2) eq 'off') {
				SpeakerPoint::AudioControl::mute_off();
			}

			else {
				dbg("UNKNOWN: $Command");
			}

		}

		elsif ($cmd =~ /^getmut (\d+)/i) {
			if (SpeakerPoint::AudioControl::get_mute()) {
				dbg("Sending mute status on");
				se($Handle, "$serial getmut ON\r\n$serial OK getmut");
			} else {
				dbg("Sending mute status off");
				se($Handle, "$serial getmut OFF\r\n$serial OK getmut");
			}
		}

		elsif ($cmd =~ /^getvol (\d+)/i) {
			if (SpeakerPoint::AudioControl::get_mute()) {
				dbg("Sending volume status (muted)");
				se($Handle, 
					"$serial getvol $1 "
					.SpeakerPoint::AudioControl::get_volume()
					."\r\n$serial OK getvol"
				);
			} else {
				dbg("Sending volume status");
				se($Handle,
					"$serial getvol $1 "
					.SpeakerPoint::AudioControl::get_volume()
					."\r\n$serial OK getvol"
				);
			}
		}

		elsif ($cmd =~ /^addch (\d+) ([^ ]+)/i) {
			dbg("Adding Channel (lol)");
			se($Handle, 
				"$serial addch Port or device already open\r\n"
				."$serial NO addch 6200\r\n"
			);
		}

	}
	return undef;
}

1;
