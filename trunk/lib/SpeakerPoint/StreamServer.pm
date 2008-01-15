package SpeakerPoint::StreamServer;
use strict;
use Audio::Mixer;
use Net::RTP::Packet;
use C4Toolkit;
use IO::Socket;
use Socket;

my @buffer;
my $bufferSize = 8;
my %ss_sockets;
my $dsp;
my $lastFrame=0;
my $lastReset=0;
my $buffersize;
my $lastSerial = 0;

sub listen {
	$buffersize = shift() || 256;

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

	return $Audio;
}

sub resetMpeg {
	close($dsp) if defined $dsp;
	@buffer = ();
	dbg("Starting mpg123, buffersize = $buffersize, internal buffersize = $bufferSize");
	open($dsp,"|mpg123 -b $buffersize -v -y --gapless -");
}

sub checkReset {
	if ( (time() - $lastFrame > 1) && $lastFrame > $lastReset) {
		dbg("Silence detected, resetting buffer");
		$lastReset = time();
		resetMpeg();
	}
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


	my ($inport, $inaddr) = sockaddr_in($Address); 
	my ($host) = inet_ntoa($inaddr);
	

	if (length($RTPFrame) == 9) {
		dbg("Got a nine-byte / control packet: ".$RTPFrame);

		my $tmp = IO::Socket::INET->new( Proto => 'udp', PeerAddr => $host, PeerPort => $inport);
		$tmp->send($RTPFrame) if $tmp;
		close($tmp);
	} else {
		my $packet;
		local $SIG{__WARN__} = sub {}; # Hide warnings
		eval { $packet = new Net::RTP::Packet( $RTPFrame ); };

		if (defined($packet) && $packet && $packet->timestamp()) {
			dbg("Got a valid RTP packet, timestamp: " . $packet->timestamp() ) ;

			if ($packet->seq_num != $lastSerial) {
				resetMpeg();
				$lastSerial = $packet->seq_num;
				dbg("Init or new song. Resetting player");
			}

			if ($packet->payload_type() == 14) { # 14 == MPA
				my $MPAFrame = $packet->payload();
				if (ord(substr($MPAFrame,0,1)) == 255 && ord(substr($MPAFrame,1,1)) == 251) { # Is a valid MPEG Audio frame.
					dbg("Received MPEG Audio frame");

					$lastFrame = time();

					push @buffer, $MPAFrame;
					
					if (@buffer >= $bufferSize) {
						for (0..$#buffer) {
							print $dsp shift(@buffer);
						}
					}

					my $sock = IO::Socket::INET->new( Proto => 'udp', PeerAddr => $host, PeerPort => $inport);
					$sock->send(sprintf("%09d", $packet->timestamp())) if $sock;
					dbg("No sock") unless $sock;
				} else {	
					dbg("Received UNKNOWN data");
				}
			}
		}
		# if not MPEG Audio, discard packet
	}
}

1;
