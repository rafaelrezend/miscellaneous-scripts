#!/usr/bin/perl

##################################################################
#    csv_script.pl
#
#	Author: Rezende, Rafael Ribeiro
#	ALARI Institute
#	Universita della Svizzera Italiana
#
#	Given an out file (for an application e.g. LU) and a log
#	file for the system, this script writes a csv file 
#	reporting, for each execution of the application, starting
#	time, completion time, execution time and energy
#	consumption.
#
#	Parameters:
#		out file
#		log file
#
#	Output:
#		output.csv
#
##################################################################

use strict;
use List::Util qw/max/;
use List::Util qw/min/;
use List::Util qw/sum/;

# checking number of input parameters
if ($#ARGV < 1) {
	print "usage: ./csv_script <log_file> <out_file1.xml out_file2.xml ...>\n";
	exit;
}

# getting log file
my $log_file 	= shift(@ARGV);
my $csv_file	= "output.csv";
my $stat_file	= "statistics.csv";

print "\nReading log file: $log_file\n";

# creating file reader
open FILE, $log_file or die $!;
my $input_data;

# reading file
while (<FILE>) {
	$input_data.=$_;
}

# closing file reader
close FILE;

# removing endline and carriage return
$input_data =~ tr/\r//d;
$input_data =~ tr/\n//d;

# split input data into lines
my @input_data_marks = split('sesc_simulation_mark ', $input_data);
# remove first unused field
shift(@input_data_marks);

# counting log marks
my $counter_log_marks = @input_data_marks;
my $counter_out_marks = 0;

print "Checking consistency... ";
if ($counter_log_marks > 1) {
	print "OK: $counter_log_marks marks\n\n";
} else {
	print "FAILED: no marks found!\n\n";
	exit;
}

# creating variables to store timestamp and accumulated energy
my @timestamp;
my @accum_energy;

# read line by line from log and allocate to variables
foreach (@input_data_marks){

	my @all_nums = $_ =~ /\d+\.?\d*/g;

	$timestamp[$all_nums[0]] = $all_nums[1];
	$accum_energy[$all_nums[0]] = $all_nums[2];
}

# setting output file
open(OUTPUT, "> $csv_file");

# Store transaction
print OUTPUT "app_name,start_mark,end_mark,delta_time\n";

# reading each out file (PER FILE)
foreach (@ARGV) {

	print "Reading out file $_ : ";
	open (FILE, $_);

	$input_data = '';

	# reading file
	while (<FILE>) {
		$input_data.=$_;
	}

	# closing file reader
	close FILE;

	# removing endline and carriage return
	$input_data =~ tr/\r//d;
	$input_data =~ tr/\n//d;

	# split input data into lines
	@input_data_marks = split(' START ', $input_data);

	# remove first unused field
	shift(@input_data_marks);

	# counting marks (START and END)
	my $counter_marks = @input_data_marks;
	$counter_marks = $counter_marks * 2;
	print "$counter_marks marks\n";
	$counter_out_marks += $counter_marks;

	# getting name of application
	my @name = split(/\d+/,$input_data_marks[0]);
	my $name = pop(@name);

	# read line by line from log and allocate to variables
	foreach (@input_data_marks){

		# get start and end indexes
		my @all_nums = $_ =~ /\d+/g;

		# get diff of timestamps
		my $delta = $timestamp[$all_nums[1]]-$timestamp[$all_nums[0]];

		print OUTPUT "$name,$all_nums[0],$all_nums[1],$delta\n";
	}

}

#close output
close OUTPUT;

print "Done!\n\nSummary:\n$counter_log_marks marks read from log file.\n$counter_out_marks marks read from out files.\n\n";


print "Getting statistic values from previous results.\n";

# creating file reader
open FILE, $csv_file or die $!;
$input_data = '';

# reading file
while (<FILE>) {
	$input_data.=$_;
}

# closing file reader
close FILE;

# removing endline and carriage return
$input_data =~ tr/\r//d;

# split input data into lines
@input_data_marks = split("\n", $input_data);

# remove title from array of results
shift(@input_data_marks);

# setting output file
open(OUTPUT, "> $stat_file");

# create matrix of apps and their respective times (hash app + vector of times)
my $app = {};

# reading each line
foreach (@input_data_marks) {

	$input_data = $_;

	# removing endline and carriage return
	$input_data =~ tr/\r//d;
	$input_data =~ tr/\n//d;

	# split input data into lines
	my @input_data_fields = split(',', $input_data);

	push (@{$app->{$input_data_fields[0]}}, $input_data_fields[3]);
}

#print title to the new file
print OUTPUT "\napp_name";
for my $key ( keys %$app ) {
        print OUTPUT ",$key";
}

#print mean line
print OUTPUT "\nmean";

my $sqsum_hash = {};

for my $key ( keys %$app ) {
	my @time_array = @{$app->{$key}};
	my $size = @time_array;
	my $mean = (sum @time_array)/$size;
        print OUTPUT ",$mean";

	# variance standard deviation depends on the mean, thus, this value is calculated first to be printed later
	my $sqsum = 0;
	for (@time_array) {
		$sqsum += ( $_ ** 2 );
	} 
	$sqsum /= $size;
	$sqsum -= ( $mean ** 2 );

	$sqsum_hash->{$key} = $sqsum;
}

#print min line
print OUTPUT "\nmin";
for my $key ( keys %$app ) {
	my @time_array = @{$app->{$key}};
	my $time = min @time_array;
        print OUTPUT ",$time";
}

#print max line
print OUTPUT "\nmax";
for my $key ( keys %$app ) {
	my @time_array = @{$app->{$key}};
	my $time = max @time_array;
        print OUTPUT ",$time";
}

#print median line
print OUTPUT "\nmedian";
for my $key ( keys %$app ) {
	my @time_array = @{$app->{$key}};
	my $median;
	my $mid = int @time_array/2;
	my @sorted_values = sort by_number @time_array;
	if (@time_array % 2) {
		$median = $sorted_values[ $mid ];
	} else {
		$median = ($sorted_values[$mid-1] + $sorted_values[$mid])/2;
	}
	print OUTPUT ",$median";
}

#print stardard deviation line
print OUTPUT "\nvariance";
for my $key ( keys %$sqsum_hash ) {
	my $sqsum = $sqsum_hash->{$key};
	print OUTPUT ",$sqsum";
}

#print stardard deviation line
print OUTPUT "\nstd_dev";
for my $key ( keys %$sqsum_hash ) {
	my $stdev = sqrt($sqsum_hash->{$key});
	print OUTPUT ",$stdev";
}

#close output
close OUTPUT;

# by_number subroutine
sub by_number {
    if ($a < $b){ -1 } elsif ($a > $b) { 1 } else { 0 }
}

print "Done!\n\n";

print "$csv_file and $stat_file files generated.\n\n";

#
#
1;


