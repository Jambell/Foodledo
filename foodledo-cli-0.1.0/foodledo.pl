#!/use/bin/perl -w  #####################################
#														#
#		foodledo.pl - a geek grocery tool				#
#		(c) James Campbell 2010							#
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
my $email = 'james@jambell.com';

print "What do you want to do?\n\n  1) Show and select recipes\n  2) Add a new recipe\n  3) Quit\n\n";
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

sub select_recipes{
  my %recipes = parse_recipes($items_file);
  my @titles = keys(%recipes);
  sort(@titles);
  print "Recipes available:\n==================\n\n";
  my %recipe_index;
  my $counter = 0;
  foreach my $title (@titles){
    $counter ++;
    $recipe_index{$counter} = $title;
    print "  $counter) $title\n";
  }
  print "\nSelect your recipes.\nYou can select multiple items by number\n(separate them with spaces)\nthen hit [enter]...\n\n";
  my $selection = <STDIN>;
  chomp($selection);
  my @selection = split(/[ \t]+/,$selection);
  my $message = '';
  foreach my $recipe (@selection){
    if(exists($recipe_index{$recipe})){
      $message .= "$recipe_index{$recipe}\n$recipes{$recipe_index{$recipe}}\n\n";
    }
  }
  &send_email($message);
  print "The shopping list is:\n\n$message";
  open LOG, "> $shopping_cache" or die "Unable to write the shopping list to $shopping_cache:$!\n";
  print LOG "$message";
  close LOG;
}

sub add_recipes{
  
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
          print "\n\n\nWARNING - THERE ARE TWO RECIPES WITH THE SAME TITLE - $title\n\n\n";
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
  # Process one more time to get the last entry in the fasta file...
  if(defined($title)){
    if(defined($title_items{$title})){
      warn "\n\n\nWARNING - THERE ARE TWO RECIPES WITH THE SAME TITLE - $title\n\n\n";
    }
    $title_items{$title} = $items;
  }
  return %title_items;
}

sub send_email{
  my $message = shift(@_);
  my $from_name = "FDLDO_mailer";
  my $from_email = 'no_reply@jambell.com';
  my $subject = "Shopping List";  
  open MAIL, "| /usr/sbin/sendmail -t -F'$from_name' -f'$from_email'" or die "Could not open sendmail: $!";
  print MAIL <<END_OF_MESSAGE;
To: $email
Subject: $subject

$message
END_OF_MESSAGE
  close MAIL or die "Could not close sendmail: $!";  
  print "Your shopping list has been sent\n\n";
}

