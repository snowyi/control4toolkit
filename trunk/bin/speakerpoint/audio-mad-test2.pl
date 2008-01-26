 use Audio::Mad qw(:all);
use IO::File;
use Audio::OSS qw(:funcs :formats);

  
  my $stream   = new Audio::Mad::Stream();
  my $frame    = new Audio::Mad::Frame();
  my $synth    = new Audio::Mad::Synth();
  my $timer    = new Audio::Mad::Timer();
  my $resample = new Audio::Mad::Resample(44100,44100);
  my $dither   = new Audio::Mad::Dither(MAD_DITHER_S16_LE);

  my $buffer = join('', <STDIN>);

  my $i=0;
$|=1;
  $buf = '';
  $stream->buffer($buffer);

  my $dsp = new IO::File(">/dev/dsp") or die "open failed: $!";
  dsp_reset($dsp) or die "reset failed: $!";

  set_fmt($dsp, AFMT_S16_LE);
  set_stereo($dsp, 1);
  set_sps($dsp, 44100);

  FRAME:
  while (1) {
	
        if ($frame->decode($stream) == -1) {
                last FRAME unless ($stream->err_ok());

                #warn "decoding error: " . $stream->error();
                next FRAME;
        }
	if ($i == 0) {
		print STDERR "Bitrate: " . $frame->bitrate() ."\n";
		print STDERR "Samplerate: " . $frame->samplerate() . "\n";
		print STDERR "Mode: " . $frame->mode() . "\n";
		print STDERR "Layer: " . $frame->layer() . "\n";
	}
	$timer += $frame->duration();

        $synth->synth($frame);

	my ($l,$r) = $synth->samples();
	#substr($l,-512) = undef;
	#substr($r,-512) = undef;
        my $pcm = $dither->dither($l,$r);

	$dsp->write($pcm);

	print STDERR "Frame: $i " . $timer . "\r";
	$i++;
  }
	print STDERR "\n";
  $dsp->close();
