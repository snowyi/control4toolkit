# Proof of concept test
use Audio::Mad qw(:all);
use Audio::DSP;

    ($buf, $chan, $fmt, $rate) = (4096, 2, AFMT_S16_BE, 44100);

    $dsp = new Audio::DSP(buffer   => $buf,
                          channels => $chan,
                          format   => $fmt,
                          rate     => $rate,
				mode => O_WRONLY,
	);

  
  my $stream   = new Audio::Mad::Stream();
  my $frame    = new Audio::Mad::Frame();
  my $synth    = new Audio::Mad::Synth();
  my $timer    = new Audio::Mad::Timer();
  my $resample = new Audio::Mad::Resample(44100,44100);
  my $dither   = new Audio::Mad::Dither(MAD_DITHER_S16_BE);

  my $buffer = join('', <STDIN>);

  my $i=0;
$|=1;
  $dsp->init() || die $dsp->errstr();
  $buf = '';
  $stream->buffer($buffer);
  FRAME:
  while (1) {
	
        if ($frame->decode($stream) == -1) {
                last FRAME unless ($stream->err_ok());

                warn "decoding error: " . $stream->error();
                next FRAME;
        }
	if ($i == 0) {
		print STDERR "Bitrate: " . $frame->bitrate() ."\n";
		print STDERR "Samplerate: " . $frame->samplerate() . "\n";
		print STDERR "Mode: " . $frame->mode() . "\n";
		print STDERR "Layer: " . $frame->layer() . "\n";
		print STDERR "Duration: " . $frame->duration() . "\n";
	}
	$timer->add($frame->duration());

        $synth->synth($frame);
	my ($l,$r) = $synth->samples();
	#substr($l,-512) = undef;
	#substr($r,-512) = undef;
        my $pcm = $dither->dither($l,$r);
	#$dsp->dwrite($pcm);
	$dsp->datacat($pcm);
	$dsp->write();
	
	print STDERR "Frame: $i " . $timer . "\r";
 #       print $pcm;
	$i++;
  }
	print STDERR "\n";
  $dsp->close();
