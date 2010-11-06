#!/usr/bin/perl -w  #####################################
#														#
#		foodledo.pl - a geeks grocery tool				#
#		(c) James Campbell 2010							#
#		www.jambell.com/foodledo/						#
#														#
#		Released under the Perl Artistic				#
#		License. For details, see:						#
#		http://dev.perl.org/licenses/artistic.html		#
#														#
#########################################################

use strict;

# Global configuration
#
# file were the recipes and items are stored
my $items_file = "./shopping_items.txt";
#
# log file where the current recipe is stored when emailing
my $shopping_cache = "./last_list.txt";
#
# Email address where the shopping list should be emailed
my $to_email = 'james@example.com';
#
# If you have sendmail on your system, specify the path
my $sendmail_path = '/usr/sbin/sendmail';
#
# End of Global configuration

# Interactive mode
print '
What do you want to do?
  1) Show and select recipes
  2) Add a new recipe\n
  3) Quit' . "\n\n";

my $choice = 0;
while($choice !~ /[1-3]/){
  $choice = <STDIN>;
  chomp($choice);
}
if($choice == 1){
  &select_recipes;
  exit;
}
elsif($choice == 2){
  &add_recipe;
  exit;
}
else{
  exit;
}

### Subroutines ###

sub select_recipes{
  my %recipes = parse_recipes($items_file);
  my @titles = keys(%recipes);
  @titles = sort(@titles);
  print "Recipes available:\n==================\n\n";
  my %recipe_index;
  my $counter = 0;
  foreach my $title (@titles){
    $counter ++;
    $recipe_index{$counter} = $title;
    print "  $counter) $title\n";
  }
  print '
  Select your recipes.
  You can select multiple items by number
  (separate them with spaces)
  then hit [enter]...' , "\n\n";
  my $selection = <STDIN>;
  chomp($selection);
  if($selection eq ''){
    print "No choices were made. Please type the numbers of the recipes you want. Separate numbers with spaces, then press enter.\n\n";
    exit;
  }
  my @selection = split(/[ \t]+/,$selection);
  my ($message, $menu, $shopping) = '';
  
  foreach my $recipe (@selection){
    if(exists($recipe_index{$recipe})){
      $menu .= "$recipe_index{$recipe}\n";
      $shopping .= "$recipes{$recipe_index{$recipe}}\n";
    }
  }
  # sort the ingredients
  my @shopping = split(/[\n\r]+/,$shopping);
  @shopping = sort(@shopping);
  $shopping = join("\n",@shopping);
  $message = "Menu:\n=====\n$menu\n\n" . "Shopping:\n=========\n$shopping\n\n";
  &send_email($message);
  print "$message";
  open LOG, "> $shopping_cache" or die "Unable to write the shopping list to $shopping_cache:$!\n";
  print LOG "$message";
  close LOG;
}

sub add_recipe{
  print '
  You are about to add one or more recipes
  to your recipe items file: ', "$items_file",'
  You need to provide a title, followed
  by a line for each ingredient. The last two
  things on the ingredient lines should be an
  amount and a value (like 200 g or 30 mL).
  When you are done entering ingredients, type:
  done
  and you\'ll be asked if you want to add
  another recipe. 
  ', "\n\n";
  open RECIPES, ">> $items_file" or die "Cannot append recipes to the recipes file $items_file:$!\n";
  my $add_more = 'yes';
  while($add_more !~ /^(n|N|no|NO|No|nO)/){
    print "Enter a recipe title:\n";
    my $title = <STDIN>;
    chomp($title);
    print "Now enter the ingredients - 1 per line with amount and units at the end\n";
    print "When you're done, type 'quit'\n\n";
    my $ingredients = '';
    my $quit = undef;
    while(!defined($quit)){
      my $line = <STDIN>;
      chomp($line);
      if($line =~ /quit/){
        $quit = 1;
      }
      else{
        $ingredients .= "$line\n";
      }
    }
    print RECIPES ">$title\n$ingredients\n";
    print "Add another recipe (Y/N)?\n";
    $add_more = <STDIN>;
  }
  close RECIPES;
}

sub parse_recipes {
  my $file = shift (@_);
  my $title = undef;
  my $items = undef;
  my %title_items;
  open INPUT, "< $file" or die "could not open file:$!";
  while (<INPUT>){
    if($_ =~ /^#.*/){
      next;
    }
    if ($_ =~ /^>[ ]*([^\n\r]+[\n\r]+)/){
      if(defined($title)){
        if(defined($title_items{$title})){
          print "\n\n\nWARNING - There are two recipes called $title\n\n\n";
        }
        $title_items{$title} = $items;
        $title = undef;
        $items = undef;
        chomp ($title = $1);
      }
      else{
        chomp ($title = $1);
      }
    }
    elsif ($_ =~ /^([^>]+[\n\r]+)/){
      $items .= $1;
    }
    else{
      next;
    }
  }
  close INPUT;
  # Process one more time to get the last entry in recipes file
  if(defined($title)){
    if(defined($title_items{$title})){
      warn "\n\n\nWARNING - There are two recipes called $title\n\n\n";
    }
    $title_items{$title} = $items;
  }
  return %title_items;
}

sub send_email{
  my $message = shift(@_);
  my $from_name = "Foodledo Menu and Shopping";
  my $from_email = 'no_reply@example.com';
  my $subject = "Shopping List";  
  open MAIL, "| $sendmail_path -t -F'$from_name' -f'$from_email'" or die "Could not open sendmail: $!";
  print MAIL <<END_OF_MESSAGE;
To: $to_email
Subject: $subject

$message
END_OF_MESSAGE
  close MAIL or die "Could not close sendmail: $!";  
  print "Your shopping list has been sent to $to_email\n\n";
}

