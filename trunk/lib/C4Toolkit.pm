package C4Toolkit;

@ISA=qw(Exporter);
@EXPORT = qw(se dbg $dbg);
@EXPORT_OK = qw();
use Exporter;
use Time::HiRes qw(time);
use strict;

our $dbg = 0;
my $StartTime = time();
my $DeviceID;

sub dbg {
	my $Message = shift;
	my ($pkg, $file, $line) = caller;
	my (undef, undef, undef, $subroutine) = caller(1);
	if ($dbg) {
		printf(
			"[%9.3f: % -30s]: %s\n",
			time() - $StartTime,
			substr(defined($subroutine) ? $subroutine : $pkg,-30),
			$Message
		);
	}
}

sub se {
        my $fh = shift;
        my $pkg = shift;
	my $dbg = $pkg;
	$dbg =~ s/[\r\n]+//sg;
	dbg("OUT: $dbg");
        print $fh $pkg."\r\n";
        return 1;
}

# Retrieve DeviceID for this computer

sub DeviceID {
	return $DeviceID if defined $DeviceID;

	my $id = `ifconfig eth0|grep HWaddr|awk '{print \$5}'`;
	$id =~ s/[^a-f0-9]+//gsi;
	$DeviceID = 'sp-'.$id;
	return $DeviceID;
}

1;
