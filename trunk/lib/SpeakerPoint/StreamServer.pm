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

sub listen {
	dbg("Opening UDP Streaming Port");

	# Streaming audio port
	my $Audio = new IO::Socket::INET(
		Proto     => 'udp',
	        LocalPort => 6200,
		LocalAddr => '10.0.0.54', #proevdeistad
	);

	# Only needed on non-posix platforms like windows
	dbg("Setting binmode to Audio-streaming port");
	binmode($Audio);

	$ss_sockets{$Audio} = 1;

	dbg("Initializing sound");
	open($dsp,"|mpg123 -b 128 -v -y --gapless -");

	dbg("Enabling autoflush");
	$dsp->autoflush(1);

#	socket(SOCKET, PF_INET, SOCK_DGRAM, getprotobyname("udp"));	

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


	my ($inport, $inaddr) = sockaddr_in($Address); 
	my ($host) = inet_ntoa($inaddr);
	dbg("p $inport a " . inet_ntoa($inaddr));

	

	if (length($RTPFrame) == 9) {
		dbg("Got a nine-byte / control packet: ".$RTPFrame);

		my $tmp = IO::Socket::INET->new( Proto => 'udp', PeerAddr => inet_ntoa($inaddr), PeerPort => $inport);
		$tmp->send($RTPFrame);
		close($tmp);
		
		#$Handle->send($RTPFrame); # if $Handle->peeraddr(); # O_o
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

					my $sock = IO::Socket::INET->new( Proto => 'udp', PeerAddr => inet_ntoa($inaddr), PeerPort => $inport);
					$sock->send(sprintf("%09d", $packet->timestamp())) if $sock;
					dbg("No sock") unless $sock;
					#$Handle->send(sprintf("%09d", $packet->timestamp())) if $Handle->peeraddr(); # O_o
				} else {	
					dbg("Received UNKNOWN data");
				}
			}
		}
		# if not MPEG Audio, discard packet
	}
}

1;
