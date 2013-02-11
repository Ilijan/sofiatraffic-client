#!/usr/bin/perl

package BusStopInfo;

# new(db)
# get_coords(stop_code) -> array [lat, lon]
# get_nearest(lat, lon, radius) -> array [stop_codes]
# 

sub new
{
	my($class, $db) = @_;
	my($self) = {
		db => $db,
	};
	
	bless $self, $class;
	return $self;
}

sub get_coords
{
	my($self, $stop_code) = @_;
	my($stop);
	
	$stop = $self->{db}->{$stop_code} // return 0;

	if(defined($stop->{lat}) && defined(exists($stop->{lon})))
	{
		return [$stop->{lat}, $stop->{lon}];
	}
	
	return 0;
}

sub get_nearest
{
	my($self, $lat, $lon, $radius) = @_;
	my($result, $coords, @delta, @square);
	$result = [];
	
	foreach $stop_code ($self->{db})
	{
		$coords = get_coords $stop_code;
		if($coords)
		{
			@delta = ($lat - $coords->[0], $lon - $coords->[1]);
			@square =  map { $_ * $_ } @delta;
			$distance = $square[0] + $square[1];
			if($distance < $radius)
			{
				push @$result, $stop_code;
			}
		}
	}
	
	return 0 if $#$result < 0;
	
	return $result;
}
