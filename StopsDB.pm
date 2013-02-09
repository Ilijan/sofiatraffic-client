#!/usr/bin/perl

package StopsDB;

use XML::Simple;

#by default save to xml
#sub new($);#hash {DB file, file_format(xml,csv...) }
#sub load($);#
#sub save();#save to current open db
#sub saveTo($);# hash {file_name, file_format(xml,csv...)}
#sub populate($);#hash {stops_values} populate only with the exsting fields in hash argument(creating new entries and updating old if needed)
#sub populate_from_file($); #hash {input_file, file_format(xml,csv...)}, ...
sub new
{
	my($class, $file) = @_;
	my($self) = {
		file	=> $file,
		db		=> _read_db($file);
	};
	
	bless $self, $class;
	return $self;
}

sub _read_db
{
	my($file) = @_;
	
	return _read_xml($file);
}

sub _read_xml
{
	my($file) = @_;
	my($xs, $content);
	
	$xs = XML::Simple->new(KeyAttr => { stop => 'code' });
	$content = $xs->XMLin($file);
	
	return $content{stop};
}

sub _save_db
{
	my($db, $file) = @_;
	
	_save_xml($db, $file);
}

sub _save_xml
{
	my($db, $file) = @_;
	my($xs, $fh);
	
	open $fh, '>:encoding(utf-8)', $file or return 0;#die "open($out_file): $!";
	$xs = XML::Simple->new(KeyAttr => 'code', OutputFile => $fh);
	$xs->XMLout({stop => $db});
	
	1;
}

sub save
{
	my $self = @_;
	$self->saveTo($self->{file});
}

sub saveTo
{
	my($self, $file) = @_;
	_save_db($self->{db}, $file);
}


sub populate
{
	my($self, $populate_info) = @_;
	my($db) = $self->{db};

	$db->{$stop} //= {};
	$db->{$stop} = {%$db->{$stop}, %$populate_info};
}

sub populate_from_file
{
	my($self, $file) = @_;
	my($file_content);
	
	$file_content = _read_db($file);
	$self->populate($file_content);
}