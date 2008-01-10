package C4Toolkit;

# Retrieve DeviceID for this computer

sub DeviceID {
	my $id = `ifconfig|grep HWaddr|awk '{print \$5}'`;
	$id =~ s/[^a-f0-9]+//gsi;
	return "sp-".$id;
}

1;
