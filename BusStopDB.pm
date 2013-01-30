#!/usr/bin/perl

package BusStopDB;

#use strict;
#use warnings;

my%virtual_table = (
	url					=> 'http://gps.skgt-bg.com/Web/SelectByLine.aspx',
	transport_type_tag	=> { name => 'ctl00$ContentPlaceHolder1$ddlTransportType' },
	lines_tag 			=> { name => 'ctl00$ContentPlaceHolder1$ddlLines' },
	routes_tag			=> { name 				=> 'ctl00$ContentPlaceHolder1$rblRoute',
							 routes_ids			=> ['ctl00_ContentPlaceHolder1_rblRoute_0',
													'ctl00_ContentPlaceHolder1_rblRoute_1']
							},
	stops_tag			=> { name => 'ctl00$ContentPlaceHolder1$ddlStops'}
);

#returns hash: keys are site text, values are option values
sub _get_select_options($$)
{
	my($w) = @_;
	my(@options, $result);
	$result = {};
	@options = $w->document->getElementsByName($virtual_table{transport_type_tag}{name})->[0];
	
	foreach(@options)
	{
		if($_->value eq '') {continue;}
		
		$result{$_->text} = $result{$_->value};
	}
	
	$result;
}

sub _choose_route_by_id($)
{
	my ($w) = @_;
	$w->eval('document.getElementById(\'ctl00_ContentPlaceHolder1_rblRoute_0\').checked = true;', 'JavaScript');
}

sub extract_info_for_stop($)
{
	my($stop) = @_;
	
}

sub _get_on_ground_transport_info
{
	my(%result, %transport_types, %transport_lines, %transport_stops, %stop_info);
	
	$w = new WWW::Scripter();
	$w->use_plugin('JavaScript');
	
	$w->get($virtual_table{url});
	
	%transport_types = _get_select_options($w, $virtual_table{transport_type_tag}{name});
	foreach $value (values %transport_types)
	{
		$w->select($virtual_table{transport_type_tag}{name}, $value);
		$w->submit();
		
		%transport_lines = _get_select_options($w, $virtual_table{lines_tag}{name});
		foreach $line_num_value (values %transport_lines)
		{
			$w->select($virtual_table{lines_tag}{name}, $line_num_value);
			$w->submit();
			
			foreach $routeid ($virtual_table{routes_tag}{routes_ids})
			{
				$w->eval('document.getElementById(\''.$route_id.'\').checked = true;', 'JavaScript');
				
				%transport_stops = _get_select_options($w, $virtual_table{stops_tag}{name});
				foreach $stop (values %transport_stops)
				{
					%stop_info = extract_info_for_stop($stop);
					$result{$stop_info{id}} = $stop_info{data};
				}
			}
		}
	}
}
#sub _get_metro_info

sub get_stops_info
{

}

1;