#!/usr/bin/perl

package BusStopInfo;

# new(db)	TODO capthca support
# get_coords(stop_code) -> array [lat, lon]
# get_nearest(lat, lon, radius) -> array [stop_codes]
# get_transport_info(stop_code) -> hash { bus => {line1 => [time1, time2...], ....}, tram => {...}, trolley_bus => {...}}
# TODO point to point route
# TODO? routes db

use WWW::Scripter;
#use lib '.';
use CaptchaSolver;
#require 'CaptchaSolver.pm';
use utf8;
@ISA = qw(Exporter);
@EXPORT = qw(new _mobile_get_stop_info);

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

sub _mobile_submit_form
{
	my($w) = @_;
	@captcha_img = grep { $_->src =~ /captcha/ } $w->document->getElementsByTagName('img');
	if($#captcha_img >= 0)
	{
		$captcha_url = 'http://m.sofiatraffic.bg'.$captcha_img[0]->src;
		$solved = solve_img $captcha_url;
		
		#$w->document->getElementById('sc')->value($solved);
		$w->eval("document.getElementById(\"sc\").value = '".$solved."';", 'JavaScript');
	}
	
	@submit_button = grep { $_->type =~ /submit/ } $w->document->getElementsByTagName('input');	#&& $_->value =~ /Провери/
	#print $submit_button[0]->value;
	$submit_button[0]->click;
	
	print '-'.$w->document->getElementById('sc')."-\n";
}

sub _mobile_extract_info_for
{
	my($w, $class_attr) = @_;
	my($result, @vehicles);
	$result = {};
	
	@vehicles = $w->document->getElementsByClassName($class_attr);
	if($#vehicles >= 0)
	{
		#print "##";
		foreach $vehicle (@vehicles)
		{
			#print '-'.$bus->innerHTML."-\n";
			$inner_html = $vehicle->innerHTML;
			my @lines = grep { length } split (/\n/, $inner_html);
			#print join('||||', @lines);
			if($lines[0] =~ /<b>(.*?)<\/b>/)
			{
				$number = $1;
			}
			if($lines[1] =~ /^(.*?)<br/) 
			{
				$times = $1;
				$times =~ s/^\s+|\s+$//rg;	#trim, the /g flag, the substitution makes all possible matches, so it gets both
			}
			
			$route = ($lines[2] =~ s/^\s+|\s+$//rg); # trim
			
			$result->{$number} = {time => $times, route => $route};
		}
		#print "##";
	}
	
	return $result;
}

# class="arr_info_2" trolley bus
# class="arr_info_1" bus
# class="arr_info_3" tram

sub _mobile_extract_results
{
	my($w) = @_;
	my($result, $text, @buses, @trams, @trolley_buses, $inner_html, $number, $times, $route);
	#$text = $w->text;
	$result = {};
	
	@buses = _mobile_extract_info_for $w, "arr_info_1";
	@trams = _mobile_extract_info_for $w, "arr_info_3";
	@trolley_buses = _mobile_extract_info_for $w, "arr_info_2";
	
	
	
	#return $text;
}

sub _mobile_get_stop_info
{
	my($self, $stop_code) = @_;
	my($w, $mobile_page, @captcha_img, $captcha_url, $solved, @submit_button, $result);
	$mobile_page = 'http://m.sofiatraffic.bg/vt';
	
	$w = WWW::Scripter->new;
	$w->use_plugin('JavaScript');
	
	$w->get($mobile_page);
	
	#$code_input = $w->document->getElementsByName('q')->[0];
	#print '-'.$code_input."-\n";
	#$code_input->value($stop_code);
	
	$w->eval("document.getElementsByName(\"q\")[0].value = ".$stop_code.";", 'JavaScript');
	
	_mobile_submit_form $w;
	print $w->content."\n\n";
	$result = _mobile_extract_results $w;
	return $result;
}

sub get_transport_info
{
	my($self, $stop_code) = @_;
	
	
}

1;