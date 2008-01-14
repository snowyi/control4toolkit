package SpeakerPoint::AudioControl;
use strict;
use Audio::Mixer;
use C4Toolkit;

my $mute_status = 0;
my @mute_volume;

sub reset {
	@mute_volume = Audio::Mixer::get_cval('vol');
	$mute_status = 0;
}

sub get_volume {
	dbg("Retreiving volume");
	if ($mute_status) {
		return $mute_volume[0];
	} else {
		my @vol = Audio::Mixer::get_cval('vol');
		return $vol[0];
	}
}

sub set_volume {
	my $vol = shift;
	dbg("Setting volume");
	Audio::Mixer::set_cval('vol',$vol,$vol);
}

sub get_mute {
	$mute_status;
}

sub mute_on {
	dbg("Muting audio mute: $mute_status");
	@mute_volume = Audio::Mixer::get_cval('vol');
	$mute_status = 1;
	Audio::Mixer::set_cval('vol',0,0);

}

sub mute_off {
	dbg("Unmuting audio: $mute_status");
	Audio::Mixer::set_cval('vol',@mute_volume);
	$mute_status = 0;
}

1;
