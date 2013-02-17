#!/usr/bin/perl

package StopsDB;

use XML::Simple;
use Data::Dumper;

#by default save to xml
#sub new  hash {DB file, file_format(xml,csv...) }
#sub load_file(file_name)
#sub save save to current open db
#sub save_to(file_name) hash {file_name, file_format(xml,csv...)}
#sub populate(hash_ref) hash {stops_values} populate only with the exsting fields in hash argument(creating new entries and updating old if needed)
#sub populate_from_file(file_name) hash {input_file, file_format(xml,csv...)}, ...

sub new
{
	my($class, $file) = @_;
	my($self) = {
		#file	=> $file,
		#db		=> _read_db($file),
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
	
	$xs = XML::Simple->new(KeyAttr => { station => 'code' });
	$content = $xs->XMLin($file);
	
	return $content->{station};
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
	
	open $fh, '>:encoding(utf-8)', $file or die "open($out_file): $!";
	$xs = XML::Simple->new(KeyAttr => 'code', OutputFile => $fh);
	$xs->XMLout({station => $db});
	
	close $fh or die "close($out_file): $!";
	
	1;
}

sub load_file
{
	my($self, $file) = @_;
	$self{file} = $file;
	_read_db $file;
}

sub get_db
{
	my($self) = @_;
	
	return $self->{db};
}

sub set_db
{
	my($self, $db) = @_;
	
	return $self->{db};
}

sub save
{
	my $self = @_;
	$self->save_to($self->{file});
}

sub save_to
{
	my($self, $file) = @_;
	_save_db($self->{db}, $file);
}

sub populate
{
	my($self, $populate_info) = @_;

	$self->{db} = {%{$self->{db}}, %$populate_info};
}

sub populate_from_file
{
	my($self, $file) = @_;
	my($file_content);
	
	$file_content = _read_db($file);
	print Dumper($file_content);
	$self->populate($file_content);
}

1;
