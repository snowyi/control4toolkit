package SpeakerPoint::StreamServer;
use strict;
use Audio::Mixer;
use Net::RTP::Packet;
use C4Toolkit;

my @buffer;
my $bufferSize = 8;
my %ss_sockets;
my $dsp;

sub listen {
	dbg("Opening UDP Streaming Port");

	# Streaming audio port
	my $Audio = new IO::Socket::INET(
		Proto     => 'udp',
	        LocalPort => 6200,
	);

	# Only needed on non-posix platforms like windows
	dbg("Setting binmode to Audio-streaming port");
	binmode($Audio);

	$ss_sockets{$Audio} = 1;

	dbg("Initializing sound");
	open($dsp,"|mpg123 -b 128 -");

	dbg("Enabling autoflush");
	$dsp->autoflush(1);


	return $Audio;
}

sub checkSocket {
	my $Handle = shift;

	if (exists $ss_sockets{$Handle}) {
		readPacket($Handle);
	}
} 

sub readPacket {
	my $Handle = shift();
	my $RTPFrame;
	my $Address = recv( $Handle, $RTPFrame, 2048, 0 );
		

	if (length($RTPFrame) == 9) {
		dbg("Got a nine-byte / control packet: ".$RTPFrame);
		$Handle->send($RTPFrame) if $Handle->peeraddr(); # O_o
	} else {
		my $packet;
		local $SIG{__WARN__} = sub {}; # Hide warnings
		eval { $packet = new Net::RTP::Packet( $RTPFrame ); };

		if (defined($packet) && $packet && $packet->timestamp()) {
			dbg("Got a valid RTP packet, timestamp: " . $packet->timestamp() ) ;

			if ($packet->payload_type() == 14) { # 14 == MPA
				my $MPAFrame = $packet->payload();
				if (ord(substr($MPAFrame,0,1)) == 255 && ord(substr($MPAFrame,1,1)) == 251) { # Is a valid MPEG Audio frame.
					dbg("Received MPEG Audio frame");
					push @buffer, $MPAFrame;

					if (@buffer >= $bufferSize) {
						for (0..$#buffer) {
							print $dsp shift(@buffer);
						}
					}
					$Handle->send(sprintf("%09d", $packet->timestamp())) if $Handle->peeraddr(); # O_o
				} else {	
					dbg("Received UNKNOWN data");
				}
			}
		}
		# if not MPEG Audio, discard packet
	}
}

1;
