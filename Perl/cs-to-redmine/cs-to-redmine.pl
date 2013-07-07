#!/usr/bin/perl

##################################################################
#     CStoRedmine.pl
#
#	Author: Rafael Ribeiro Rezende
#	ALARI Institute
#	Universita della Svizzera Italiana
#
#	This application converts XML statements from N files
#	to SQL script containing INSERTs for respective data.
#
#	Parameters:
#		database	- name of database
#		table		- name of table
#		output file 	- resulting script file
#		file xml 	- data formatted in XML statements
#
#
##################################################################

use strict;
use Data::Dumper;

##################################################################
# BEGIN CONFIGURATION

# Mapping "CardScan" fields => "Redmine" database fields
# Every variable is initialized with empty value and concatenated
# with the acquired values in order to avoid overwrite. i.e. Phone
# and Fax variables.
my $mapping = {
        'First_Name' => 'first_name',
	'Middle_Name' => 'middle_name',
	'Last_Name' => 'last_name',
	'Title' => 'job_title',
	'Company' => 'company',
	'Address_Line_1' => 'address',
	'Address_Line_2' => 'address',
	'City' => 'address',
	'State' => 'address',
	'Zip_Code' => 'address',
	'Country' => 'address',
	'2nd_Address_Line_1' => 'address',
	'2nd_Address_Line_2' => 'address',
	'2nd_City' => 'address',
	'2nd_State' => 'address',
	'2nd_Zip_Code' => 'address',
	'2nd_Country' => 'address',
	'Phone' => 'phone',
	'Phone_-_Mobile' => 'phone',
	'Phone_-_Home' => 'phone',
	'Phone_-_Pager' => 'phone',
	'Phone_-_Alt_Fax' => 'phone',
	'Phone_-_Alt_Home' => 'phone',
	'Phone_-_Direct' => 'phone',
	'Phone_-_Home_Fax' => 'phone',
	'Phone_-_Main' => 'phone',
	'Phone_-_Sales' => 'phone',
	'Phone_-_Telex' => 'phone',
	'Phone_1' => 'phone',
	'Phone_2' => 'phone',
	'Phone_3' => 'phone',
	'Phone_4' => 'phone',
	'Phone_5' => 'phone',
	'Phone_6' => 'phone',
	'Fax' => 'phone',
	'Email' => 'email',
	'Email_1' => 'email',
	'Email_2' => 'email',
	'Email_3' => 'email',
	'Web_Page' => 'website',
	'Notes' => 'background',
	'Categories' => 'background'
    };

# Prefix to be inserted before any field specified below.
# Redmine Contacts does not specify the phone and fax number. Thus,
# a prefix can be used before inserting into database.
my $prefix = {
	'Phone_-_Mobile' => '(Mobile) ',
	'Phone_-_Home' => '(Home) ',
	'Phone_-_Pager' => '(Pager) ',
	'Phone_-_Alt_Fax' => '(Alt_Fax) ',
	'Phone_-_Alt_Home' => '(Alt_Home) ',
	'Phone_-_Direct' => '(Direct) ',
	'Phone_-_Home_Fax' => '(Home Fax) ',
	'Phone_-_Main' => '(Main) ',
	'Phone_-_Sales' => '(Sales) ',
	'Phone_-_Telex' => '(Telex) ',
	'Phone_1' => '(Phone 1) ',
	'Phone_2' => '(Phone 2) ',
	'Phone_3' => '(Phone 3) ',
	'Phone_4' => '(Phone 4) ',
	'Phone_5' => '(Phone 5) ',
	'Phone_6' => '(Phone 6) ',
	'Fax' => '(Fax) ',
	'Categories' => "\nCategories: "
    };

# Suffix to be inserted after any field specified below.
my $suffix = {
	'Phone' => ',',
	'Phone_-_Mobile' => ',',
	'Phone_-_Home' => ',',
	'Phone_-_Pager' => ',',
	'Phone_-_Alt_Fax' => ',',
	'Phone_-_Alt_Home' => ',',
	'Phone_-_Direct' => ',',
	'Phone_-_Home_Fax' => ',',
	'Phone_-_Main' => ',',
	'Phone_-_Sales' => ',',
	'Phone_-_Telex' => ',',
	'Phone_1' => ',',
	'Phone_2' => ',',
	'Phone_3' => ',',
	'Phone_4' => ',',
	'Phone_5' => ',',
	'Phone_6' => ',',
	'Fax' => ',',
	'Email' => ',',
	'Email_1' => ',',
	'Email_2' => ',',
	'Email_3' => ',',
	'Country' => "\n",
	'2nd_Country' => "\n"
    };

# Redmine fields to be filled
my $redmine_database = {
        'first_name' => "",
	'middle_name' => "",
	'last_name' => "",
	'job_title' => "",
	'company' => "",
	'address' => "",
	'phone' => "",
	'email' => "",
	'website' => "",
	'background' => ""
    };

if ($#ARGV != 3) {
	print "usage: ./CStoRedmine <Redmine database user> <Redmine database password> <Redmine project name> <CardScan exported file>\n";
	exit;
}

# Database name. Default name for Redmine Installation is "redmine"
my $database_name	= "redmine";

# END CONFIGURATION
##################################################################



my $database_user 	= shift(@ARGV);
my $database_pass	= shift(@ARGV);
my $project_name 	= shift(@ARGV);
my $cardscan_file 	= shift(@ARGV);

my $output_file	= "CStoRedmine_output.sql";

print "Database name: $database_name\n";
print "CardScan File: $cardscan_file\n";

print "Retrieving the ID of $project_name from database: ";

# setting output file
open(OUTPUT, "> $output_file");

print OUTPUT "SELECT proj.id FROM $database_name.projects proj WHERE proj.name = \"$project_name\";";
my @execute = split(/\n/,`mysql --user=$database_user --password=$database_pass $database_name < $output_file`);
my $project_id = $execute[1];

close(OUTPUT);

if ($project_id eq ""){
	print "\nERROR: Project $project_name not found.\n";
	exit;
}

print "$project_id\n\n";

# reading from file
my $input_data;

print "Reading file $cardscan_file\n";
open FILE, $cardscan_file or die $!;

while (<FILE>) {
	$input_data.=$_;
}

# remove "" a carriage return (\r) from input data
$input_data =~ tr/\"//d;
$input_data =~ tr/\r//d;

# split input data into lines
my @input_data_lines = split(/\n/, $input_data);

# remove title from array of lines
my $title = shift(@input_data_lines);

# split title into columns
my @title_fields = split(/\t/, $title);

# get number of columns of the table
my $size = @title_fields;

# for each contact
foreach (@input_data_lines) {

	my @contact = split(/\t/, $_);

	my $count = 0;

	for ($count = 0; $count < $size; $count++) {

		# write only if CardScan field is not empty
		if (@contact[$count]) {

			my $separator = "";

			# insert space if redmine field already has content
			if ($redmine_database->{$mapping->{@title_fields[$count]}}) {
				$separator = " ";
			}

			# add content from every contact into redmine database fields

			$redmine_database->{$mapping->{@title_fields[$count]}} .= $separator;
			$redmine_database->{$mapping->{@title_fields[$count]}} .= $prefix->{@title_fields[$count]};
			$redmine_database->{$mapping->{@title_fields[$count]}} .= @contact[$count];
			$redmine_database->{$mapping->{@title_fields[$count]}} .= $suffix->{@title_fields[$count]};

		}
	}

	# remove invalid fields
	delete $redmine_database->{''};

	my $contact_id = checkContact($redmine_database);

	unless ($contact_id) {
		
		print "Adding new contact $redmine_database->{last_name}, $redmine_database->{first_name} $redmine_database->{middle_name}: ";
		insertContact($redmine_database);
		
		$contact_id = checkContact($redmine_database);
		if ($contact_id) { print "SUCCESS\n"; }
		else { print "FAILED\n"; }

		insertContactProject($project_id, $contact_id);

	}
	else {
		my $project_name = checkContactProject($contact_id);
		print "Contact $redmine_database->{last_name}, $redmine_database->{first_name} $redmine_database->{middle_name} already exists in $project_name project.\n"; }
		

	#print Dumper($redmine_database);

	for (keys %$redmine_database)
    	{
        	delete $redmine_database->{$_};
    	}

}


# Select contact from database to check if already exists
# This procedure avoid redundant insertion, since the primary key
# of database is the "id" field, which does not have a correlation
# in CardScan application.
sub checkContact
{
	my ($redmine_database) = @_;

	# setting output file
	open(OUTPUT, "> $output_file");

	my $first_name = "first_name = \"$redmine_database->{first_name}\"";
	my $middle_name = "middle_name = \"$redmine_database->{middle_name}\"";
	my $last_name = "last_name = \"$redmine_database->{last_name}\"";

	unless ($redmine_database->{first_name}) {
		$first_name = "(first_name = \"\" OR first_name IS NULL)"; }

	unless ($redmine_database->{middle_name}) {
		$middle_name = "(middle_name = \"\" OR middle_name IS NULL)"; }

	unless ($redmine_database->{last_name}) {
		$last_name = "(last_name = \"\" OR last_name IS NULL)"; }

	my $query = "SELECT id FROM $database_name.contacts WHERE $first_name AND $middle_name AND $last_name;";

	my @execute = executeQuery($query);
	my $contact_id = $execute[1];

	return $contact_id;
}

# Insert contact into contacts table of Redmine Database
sub insertContact
{
	my ($redmine_database) = @_;

	my $keys = "\`id\`, \`created_on\`, \`updated_on\`";
	my $values = "NULL, NOW(), NOW()";

	for (keys %$redmine_database)
	{
		$keys .= ",\`".$_."\`";
		$values .= ",\'".$redmine_database->{$_}."\'";
	}
	
	my $insert = "INSERT INTO \`$database_name\`.\`contacts\` ( $keys ) VALUES ( $values );\n";

	executeQuery($insert);
	
}

# Insert contact into contacts_project table of Redmine Database
sub insertContactProject
{
	my ($project_id, $contact_id) = @_;
	
	my $insert = "INSERT INTO \`$database_name\`.\`contacts_projects\` ( \`project_id\`, \`contact_id\` ) VALUES ( $project_id, $contact_id );\n";
	
	executeQuery($insert);

}

# Check the name of the project which the contact belongs to.
sub checkContactProject
{
	my ($contact_id) = @_;
	
	my $insert = "SELECT proj.name FROM \`$database_name\`.\`projects\` proj, \`$database_name\`.\`contacts_projects\` cproj WHERE cproj.contact_id = $contact_id AND cproj.project_id = proj.id;\n";
	
	my @execute = executeQuery($insert);

	my $project_name = $execute[1];
	
	return $project_name;
}

# General query execution
sub executeQuery
{
	my ($query) = @_;

	# setting output file
	open(OUTPUT, "> $output_file");
	print OUTPUT $query;
	my @execute = split(/\n/,`mysql --user=$database_user --password=$database_pass $database_name < $output_file`);
	close(OUTPUT);

	return @execute;

}


#
#
1;


