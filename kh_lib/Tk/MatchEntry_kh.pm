#
# MatchEntry is an entry widget with auto-completion capabilities. It attempts
# to fill the gap in functionality between Tk::BrowseEntry and Tk::HistEntry
# with focus on user-friendliness concerning the auto-completion.
# 

# Set package name
package Tk::MatchEntry;

# Set version information
our $VERSION = '0.5';

# Define dependencies
use strict;
# use warnings;       # use warnings for debugging purposes
use Tk qw(Ev);
use Carp;
# use Data::Dumper;   # for debugging
require Tk::Frame;
require Tk::LabEntry;

# Construct widget
use base qw(Tk::Frame);
Construct Tk::Widget 'MatchEntry';

# Compositing the widget
sub Populate {
    my ($self, $args) = @_;

    $self->SUPER::Populate($args);  # let ancestors populate first

    # Create the entry subwidget
    #my $labelpack = delete $args->{-labelPack};
    #unless (defined $labelpack) {
    #    $labelpack = [-side => 'left', -anchor => 'e']; # set defaults
    #}
    my $content = ""; # initialize entry text
    my $entry = $self->LabEntry(#-labelPack       => $labelpack, #kh
                                -label           => delete $args->{-label},
                                -textvariable    => \$content,
                                -exportselection => 0);
    $self->Advertise('entry' => $entry); # make it available to outside
    $entry->pack(-side   => 'right', 
                 -fill   => 'x', 
                 -expand => 1); # place the entry widget in our frame

    # Create the popup-listbox
    my $popup_frame = $self->Toplevel(-bd => 2, -relief => 'raised');
    $popup_frame->overrideredirect(1); # turn off window decorations
    $popup_frame->withdraw; # start hidden
    # set exportselection to 0 in the listbox widget so we can have
    # selections in both the entry and the listbox widget at the same time
    my $scrolled_listbox = $popup_frame->Scrolled(
        qw/Listbox -selectmode browse -scrollbars oe -exportselection 0 -font TKFN/
        );
    $self->Advertise('choices' => $popup_frame);
    $self->Advertise('slistbox' => $scrolled_listbox);
    $scrolled_listbox->pack(-expand => 1, -fill => 'both', -padx => 5); # place it    
    
    # Other initializations
    $self->set_bindings;    # Set up keyboard and mouse bindings
    $self->{'popped'} = 0;  # Start with hidden listbox
    $self->Delegates('insert' => $scrolled_listbox,
                     'delete' => $scrolled_listbox,
                     'get'    => $scrolled_listbox,
                     DEFAULT  => $entry);
                 
    $self->ConfigSpecs(
        -bottomcmd   => [qw/CALLBACK bottomCmd   BottomCmd/,  undef],
        -browsecmd   => [qw/CALLBACK browseCmd   BrowseCmd/,  undef],
        -entercmd    => [qw/CALLBACK enterCmd    EnterCmd/,   undef],
        -listcmd     => [qw/CALLBACK listCmd     ListCmd/,    undef],
        -mm_onecmd   => [qw/CALLBACK mm_oneCmd   mm_OneCmd/,  undef],
        -mm_zerocmd  => [qw/CALLBACK mm_zeroCmd  mm_ZeroCmd/, undef],
        -onecmd      => [qw/CALLBACK oneCmd      OneCmd/,     undef],
        -sortcmd     => [qw/CALLBACK sortCmd     SortCmd/,    undef],
        -tabcmd      => [qw/CALLBACK tabCmd      TabCmd/,     undef],
        -topcmd      => [qw/CALLBACK topCmd      TopCmd/,     undef],
        -zerocmd     => [qw/CALLBACK zeroCmd     ZeroCmd/,    undef],
        
        -invcmd     => [qw/CALLBACK invCmd     InvCmd/,    undef],
        
        -command     => '-browsecmd',
        -ignorecase  => '-case',
        -options     => '-choices',
        -variable    => '-textvariable',

        -choices     => [qw/METHOD   choices     Choices/,    undef],
        -state       => [qw/METHOD   state       State        normal/],
        -popup       => [qw/METHOD   popup       Popup/,      undef],
        
        -autopopup   => [qw/PASSIVE  autoPopup   AutoPopup    1/],
        -autoshrink  => [qw/PASSIVE  autoShrink  AutoShrink   1/],
        -autosort    => [qw/PASSIVE  autoSort    AutoSort     1/],
        -case        => [qw/PASSIVE  case        Case         0/],
        -colorstate  => [qw/PASSIVE  colorState  ColorState/, undef],
        -complete    => [qw/PASSIVE  complete    Complete     1/],
        -fixedwidth  => [qw/PASSIVE  fixedWidth  FixedWidth   1/],
        -listwidth   => [qw/PASSIVE  listWidth   ListWidth/,  undef],
        -matchprefix => [qw/PASSIVE  matchPrefix MatchPrefix/,undef],
        -maxheight   => [qw/PASSIVE  maxHeight   MaxHeight    5/],
        -multimatch  => [qw/PASSIVE  multiMatch  MultiMatch   0/],
        -sorttrigger => [qw/PASSIVE  sortTrigger SortTrigger/,undef],
        -wraparound  => [qw/PASSIVE  wrapAround  WrapAround   0/],

        DEFAULT     => [[$entry, $scrolled_listbox]]
        );        
}

# Set up the keyboard and mouse event bindings
sub set_bindings {
    my ($self) = @_;
    my $entry = $self->Subwidget('entry');

    # Set the bind tags
    $self->bindtags([$self, 'Tk::MatchEntry', $self->toplevel, 'all']);
    $entry->bindtags([$entry, $entry->toplevel, 'all']);

    # Bindings for the entry widget
    #$entry->bind('<Down>', [$self, 'open_and_focus_listbox']);
    $entry->bind('<Down>',         [$self, 'entry_cursor_down']);
    $entry->bind('<Up>',           [$self, 'entry_cursor_up']);
    $entry->bind('<Escape>',       sub{});
    $entry->bind('<Tab>',          [$self, 'entry_tabulator']);
    $entry->bind('<Return>',       [$self, 'entry_return']);
    $entry->bind('<FocusOut>',     [$self, 'entry_leave']);
    $entry->bind('<Any-KeyPress>', sub {
            my $event = $_[0]->XEvent;
            $self->entry_anykey($event->K, $event->s); # Key, State
        });
    
    # Bindings for the listbox
    my $scrolled_list = $self->Subwidget('slistbox');
    my $listbox = $scrolled_list->Subwidget('listbox');
    $listbox->bind('<ButtonRelease-1>', [$self, 'release_listbox',
                                         Ev('x'), Ev('y')]);
    $listbox->bind('<Escape>' =>        sub{});
    $listbox->bind('<Return>' =>        [$self, 'return_listbox', $listbox]);
    $listbox->bind('<Tab>' =>           [$self, 'listbox_tab', $listbox]);
    
    # Close listbox if clicked outside
    $self->bind('<1>', 'open_listbox');
}

# Called when the entry widget loses focus to make sure any text is deselected
sub entry_leave {
    my $self = shift;
    
    $self->entry_prepare_leave;
}

# Called when the user hits <Return> within the entry widget
sub entry_return {
    my $self = shift;

    if ( $self->{popped} && $self->{selected} ){
        $self->copy_selection_listbox;;
    } else {
        # Execute given callback
        $self->Callback(-entercmd => $self);
    }
    # Hide the listbox, if popped up, deselect all entry text, place cursor
    # at end of entry widget
    $self->entry_prepare_leave;
}

# Called when the user hits <Tab> within the entry widget
sub entry_tabulator {
    my $self = shift;
    # Execute given callback
    $self->Callback(-tabcmd => $self); 
    # Hide the listbox, if popped up, deselect all entry text, place cursor
    # at end of entry widget
    $self->entry_prepare_leave;
}

# Hide the listbox, if popped up, deselect all entry text, place cursor
# at end of entry widget
sub entry_prepare_leave {
    my $self = shift;
    my $entry = $self->Subwidget('entry');

    # close the listbox if popped up
    if ($self->{'popped'}) {
        $self->hide_listbox;
    }
    
    # clear the selection
    $entry->selection('clear');

    # place the input cursor at end of entry widget
    $entry->icursor($entry->index('end'));

    # finalize the auto-completion
    $self->check_choice_case;
}

# If we have case-insensitive auto-completion, check whether the text in the
# entry widget matches one of the choices (case-insensitively). If so, replace
# it with the choice. This allows the user to enter "john doe", but makes sure
# the result is "John Doe" when the MatchEntry widget is left.
sub check_choice_case {
    my $self = shift;
    my $entry = $self->Subwidget('entry');

    return unless ($self->cget(-case)); # abort if case sensitive matching

    my $text = $entry->get; # text in entry widget

    my $all_choices_r = $self->{Configure}{all_choices_r};
    my @all_choices = @$all_choices_r;

    foreach my $choice (@all_choices) { # loop over all choices
        # check whether choice matches text case-insensitively but not
        # case-sensitively
        if ($text =~ m/^\Q$choice\E$/i && ($text ne $choice)) {
            # if so, replace the text in the entry widget with the choice
            $entry->delete(0, 'end');
            $entry->insert(0, $choice);
            $entry->icursor($entry->index('end'));
        }
    }   
}

# called when the user presses <Escape> in the entry widget
sub entry_escape {
    my $self = shift;
    my $entry = $self->Subwidget('entry');

    # Close listbox if popped up
    if ($self->{'popped'}) {
        $self->hide_listbox;
        $entry->selectionRange($entry->index('insert'),
                               $entry->index('end')); 
        # assume that another <Escape> follows
        $self->{Configure}{double_escape_possible} = 1;
    }
    else {
        # undo auto-completion otherwise
        if ($entry->selectionPresent()) {
            $entry->delete($entry->index("sel.first"), 
                           $entry->index("sel.last"));
        }
        elsif ($self->{Configure}{double_escape_possible}) {
            # no text selected -> cut from current insert position to end
            $entry->delete($entry->index("insert"),
                           $entry->index("end"));
            # turn off double-<Escape> assumption
            $self->{Configure}{double_escape_possible} = 0;
        }
    } 
}

# Called whenever the user presses any key within the entry widget
sub entry_anykey {
    my ($self, $key, $state) = @_;
    my $entry = $self->Subwidget('entry');

    # turn off double-escape mode for turning off auto-completion
    $self->{Configure}{double_escape_possible} = 0;

    # Check entry length, call appropriate callbacks
    my $entry_length = length $entry->get;
    if ($entry_length == 0) {
        $self->Callback(-zerocmd => $self); 
    }
    elsif ($entry_length >= 1) {
        $self->Callback(-onecmd => $self); 
    }
     
    if ($self->cget(-multimatch)) {
        if ($key =~ m/^Left|^Right|^Home|^End/) {
            $self->hide_listbox;
        } 
    }

    # print ">>>$key<<<\n";
    my $trigger = $self->cget(-sorttrigger);
    if (defined $trigger) {
        $self->resort if ($key =~ m/$trigger/);
    }

    $self->{Configure}{was_real_input} = 0;
    
    return if ($key =~ m/^Shift|^Control|^Left|^Right|^Home|^End/);
    return if ($state =~ m/^Control-/);

    $self->{Configure}{was_real_input} = 1;

    # check whether we are in multimatch mode
    if ($self->cget(-multimatch)) {
        return $self->entry_anykey_multimatch($key, $state, $entry);
    }
    
    # automatically pop the listbox up if requested by programmer
    # and the user has already entered at least 1 character
    if ($self->cget(-autopopup) && length $entry->get) {
        if ($self->{popped}) { # already popped up, just filter entries
            my $last_num = $self->{Configure}{last_number_of_entries};
            my $num_entries = $self->listbox_filter;
    
            $num_entries = 0 unless (defined $num_entries);
            
            # number of choices has changed, redraw the listbox
            unless ($last_num == $num_entries) {
                $self->hide_listbox;
                $self->show_listbox;
            }
        }
        else { # pop the listbox up, automatically calls the filter
            $self->show_listbox;
        }
    }
    else { # check length of input, close listbox if too short
        unless (length $entry->get) {
            $self->hide_listbox;
        }
    }

    # Skip the rest if user pressed Backspace or Delete
    return if ($key eq "BackSpace" or $key eq "Delete");
    
    #$self->entry_autocomplete;    
}

# Handle any keypress in multimatch mode
sub entry_anykey_multimatch {
    my ($self, $key, $state, $entry) = @_;

    # automatically pop the listbox up if requested by programmer
    # and the user has already entered at least 1 character in the
    # current word
    
    my $text = $entry->get;
    my $cursor = $entry->index('insert');
    (my $typed_text = $text) =~ s/^(.{$cursor})(.*)/$1/;
    my $text_after_cursor = $2;
     
    (my $current_word = $typed_text) =~ s/.*\s(.*)/$1/;
    
    my $word_length = length $current_word;
    if ($word_length == 0) {
        $self->Callback(-mm_zerocmd => $self); 
    }
    elsif ($word_length == 1) {
        $self->Callback(-mm_onecmd => $self); 
    }
    
    # print "current word: $current_word\n";
    
    if ($self->cget(-autopopup) && length $current_word) {
        if ($self->{popped}) { # already popped up, just filter entries
            my $last_num = $self->{Configure}{last_number_of_entries};
            my $num_entries = $self->listbox_filter($current_word);
    
            $num_entries = 0 unless (defined $num_entries);
            
            # number of choices has changed, redraw the listbox
            unless ($last_num == $num_entries) {
                $self->hide_listbox;
                $self->show_listbox($current_word);
            }
        }
        else { # pop the listbox up, automatically calls the filter
            $self->show_listbox($current_word);
        }
    }
    else { # check length of input, close listbox if too short
        unless (length $current_word) {
            $self->hide_listbox;
        }
    }

    # Skip the rest if user pressed Backspace or Delete
    return if ($key eq "BackSpace" or $key eq "Delete");
    
    $self->entry_autocomplete_multimatch;
}

# attempt to auto-complete the entry
sub entry_autocomplete {
    return 1;
    my $self = shift;
    my $entry = $self->Subwidget('entry');
    
    # check whether we are in multimatch mode
    if ($self->cget(-multimatch)) {
        return $self->entry_autocomplete_multimatch;
    }
    
    if ($self->cget(-complete)) { # do we want auto-completion at all?
        my $text = $entry->get;
        my $cursor = $entry->index('insert');
        (my $typed_text = $text) =~ s/^(.{$cursor})(.*)/$1/;
        my $text_after_cursor = $2;

        # check whether any text after insert cursor is from auto-completion
        my $non_auto_text;
        $non_auto_text = 1 if ($text_after_cursor ne "");
        if ($non_auto_text && $entry->selectionPresent) {
            $non_auto_text = 0
                if (($entry->index('end') == $entry->index('sel.last')) && 
                    ($entry->index('insert') == $entry->index('sel.first')));
        }
        
        # skip if position = 0 or there's text after the insert cursor
        unless($cursor == 0 || $text eq "" || $non_auto_text) {
            # search for the first matching entry
            my $ignore_case = ($self->cget(-case) ? "(?i)" : "");
            my $all_choices_r = $self->{Configure}{all_choices_r};
            my @all_choices = @$all_choices_r;

            my $prefix = $self->cget(-matchprefix) || "";
            
            my $index = 0;
            foreach my $choice (@all_choices) { # @all_choices is sorted
                if ($choice =~ m/^${ignore_case}$prefix\Q$typed_text\E(.*)/) {
                    my $choice_tail = $1; # auto-completed part of entry

                    #print "..$choice_tail..\n";
                    
                    $entry->selection('clear');
                    $entry->delete($cursor, 'end');
                    $entry->insert($cursor, $choice_tail);
                    $entry->selection('range', $cursor, 'end');
                    $entry->icursor($cursor);

                    last; # break out of foreach $choice
                }
            }    
        }
    }
}

# attempt to auto-complete the current word in multimatch mode
sub entry_autocomplete_multimatch {
    my $self = shift;
    my $entry = $self->Subwidget('entry');

    if ($self->cget(-complete)) { # do we want auto-completion at all?
        my $text = $entry->get;
        my $cursor = $entry->index('insert');
        (my $typed_text = $text) =~ s/^(.{$cursor})(.*)/$1/;
        my $text_after_cursor = $2;
        
        my $rest_of_line = '';
        # check whether the user is editing a word which is not the
        # last on the line
        if ($text_after_cursor =~ m/\s/) {
            ($rest_of_line = $text_after_cursor) =~ s/(.*?)\s(.*)/$2/;
            $text_after_cursor = $1;
        }

        # extract last word on line
        if ($typed_text =~ m/\s/) {
            $typed_text =~ s/.*\s(.*)/$1/;
        }
        
        # check whether any text after insert cursor is from auto-completion
        my $non_auto_text;
        $non_auto_text = 1 if ($text_after_cursor ne "");
        if ($non_auto_text && $entry->selectionPresent) {
            $non_auto_text = 0
                if (($entry->index('end') == $entry->index('sel.last')) && 
                    ($entry->index('insert') == $entry->index('sel.first')));
        }
        
        # skip if position = 0 or there's text after the insert cursor
        unless($typed_text eq "" || $non_auto_text) {
            # search for the first matching entry
            my $ignore_case = ($self->cget(-case) ? "(?i)" : "");
            my $all_choices_r = $self->{Configure}{all_choices_r};
            my @all_choices = @$all_choices_r;

            my $prefix = $self->cget(-matchprefix) || "";
            
            my $index = 0;
            foreach my $choice (@all_choices) { # @all_choices is sorted
                if ($choice =~ m/^${ignore_case}$prefix\Q$typed_text\E(.*)/) {
                    my $choice_tail = $1; # auto-completed part of entry
                    $entry->selection('clear');
                    $entry->delete($cursor, 'end');
                    $entry->insert($cursor, $choice_tail);
                    $entry->selection('range', $cursor, 'end');
                    if (length $rest_of_line) {
                        $entry->insert('end', " " . $rest_of_line);
                    }
                    $entry->icursor($cursor);

                    last; # break out of foreach $choice
                }
            }    
        }
    } 
}

# called when the <Down> key is pressed within the entry
sub entry_cursor_down {
    my $self = shift;
    my $listbox = $self->Subwidget('slistbox')->Subwidget('listbox');
    my $entry = $self->Subwidget('entry');
    
    $self->{Configure}{was_real_input} = 0;
    # print "entry_cursor_down\n";
 
    my $index;
    # unless it's already there, open the listbox and focus first entry
    unless($self->{popped}) {
        if ($self->cget(-multimatch)) {
            my $text = $entry->get;
            my $cursor = $entry->index('insert');
            (my $typed_text = $text) =~ s/^(.{$cursor})(.*)/$1/;
            (my $current_word = $typed_text) =~ s/.*\s(.*)/$1/;
            $self->open_listbox($current_word);
        }
        else {
            $self->open_listbox;
        } 

        $listbox->selection('clear', 0, 'end');
        $listbox->selectionSet(0);
        $listbox->activate(0);
        $index = 0;
        $self->{selected} = 1;
    }
    else { # otherwise move selection one down, unless already at bottom
        # print "one down\n";        
        if ($self->cget(-multimatch)) {
            my $text = $entry->get;
            my $cursor = $entry->index('insert');
            (my $typed_text = $text) =~ s/^(.{$cursor})(.*)/$1/;
            (my $current_word = $typed_text) =~ s/.*\s(.*)/$1/;
            $self->listbox_filter($current_word);
        }
        else {
            $self->listbox_filter;
        } 
        
        $index = $self->listbox_index;
        $index -= 1 unless $self->{selected};
        $self->{selected} = 1;
        #print "entry_cursor_down: index: $index\n";
        if ($index < $self->{Configure}{last_number_of_entries} - 1) {
            $index++;

            # check whether no element was selected before
            $index = 0 if ($index == 1 && !$listbox->selectionIncludes(0));
            
            $listbox->selection('clear', 0, 'end');
            $listbox->selectionSet($index);
            $listbox->activate($index);
        }
        else {
            $self->Callback(-bottomcmd => $self); 
            if ($self->cget(-wraparound)) {
                $index = 0;
                $listbox->selection('clear', 0, 'end');
                $listbox->selectionSet($index);
                $listbox->activate($index);               
            }
        }
    }

    $listbox->see($index);
    #$self->listbox_copy_to_entry;
    $self->entry_select_from_cursor_to_end;
}

sub entry_cursor_up {
    my $self = shift;
    my $listbox = $self->Subwidget('slistbox')->Subwidget('listbox');
    my $entry = $self->Subwidget('entry');
     
    my $index;
    
    $self->{Configure}{was_real_input} = 0;
 
    # unless it's already there, open the listbox and focus first entry
    unless($self->{popped}) {

        if ($self->cget(-multimatch)) {
            my $text = $entry->get;
            my $cursor = $entry->index('insert');
            (my $typed_text = $text) =~ s/^(.{$cursor})(.*)/$1/;
            (my $current_word = $typed_text) =~ s/.*\s(.*)/$1/;
            $self->open_listbox($current_word);
        }
        else {
            $self->open_listbox;
        } 
 
        $listbox->selection('clear', 0, 'end');
        $listbox->selectionSet(0);
        $listbox->activate(0);        
        $index = 0;
    }
    else { # otherwise move selection one up, unless already at top
        if ($self->cget(-multimatch)) {
            my $text = $entry->get;
            my $cursor = $entry->index('insert');
            (my $typed_text = $text) =~ s/^(.{$cursor})(.*)/$1/;
            (my $current_word = $typed_text) =~ s/.*\s(.*)/$1/;
            $self->listbox_filter($current_word);
        }
        else {
            $self->listbox_filter;
        } 
        $index = $self->listbox_index;
        if ($index > 0) {
            $index--;
        }
        else {
            $self->Callback(-topcmd => $self); 
            if ($self->cget(-wraparound)) {
                $index = $self->{Configure}{last_number_of_entries} - 1;
                $listbox->selection('clear', 0, 'end');
                $listbox->selectionSet($index);
                $listbox->activate($index);               
            }
        }
        
        $listbox->selection('clear', 0, 'end');
        $listbox->selectionSet($index);
        $listbox->activate($index);
    }

    $listbox->see($index);    
    #$self->listbox_copy_to_entry;
    $self->entry_select_from_cursor_to_end; 
} 

# Select text in the entry widget, from current cursor position to end
sub entry_select_from_cursor_to_end {
    my $self = shift;
    my $entry = $self->Subwidget('entry');

    # set insertion cursor to begin of line if the last listbox
    # filtering process was successful only because of -matchprefix
    # (beginning of current word in multi-match mode)

    if ($self->{Configure}{last_filter_matched_by_prefix_only}) {
        if ($self->cget(-multimatch)) {
            my $pos = $entry->index('insert');
            (my $text = $entry->get) =~ s/^(.{$pos})/$1/;
            $text =~ s/(.*)\s.*/$1/;
            # print $text."\n";
            # print "..." . length $text , "\n(of $pos)\n";
            if (length $text > $pos) {
                if ($text =~ m/(.{$pos})/) {
                    my $t = $1;
                    $t =~ s/(.*)\s.*/$1/;
                    # print "...$t\n";
                    $entry->icursor(1 + length $t);
                }
                else {
                    $entry->icursor($pos);
                }
            }
            else {
                $entry->icursor(1 + length $text);  
            }
        }
        else {
            $entry->icursor(0);
        }
    }
        
    if ($self->cget(-multimatch)) {
        my $pos = $entry->index('insert');
        (my $text = $entry->get) =~ s/^.{$pos}(.*)/$1/;
        if ($text =~ m/\s/g) {
            $pos += pos($text) - 1;
            # print "spacematch: $text\n";
        }
        else {
            $pos = $entry->index('end');
        }
        # print "pps: $pos\n";
        $entry->selectionRange($entry->index('insert'),
                               $pos); 
    }
    else {
        $entry->selectionRange($entry->index('insert'),
                               $entry->index('end')); 
    }
}
    
# called when mouse button 1 is released within the listbox
sub release_listbox {
    my ($self, $x, $y) = @_;
    $self->choose_listbox($x, $y);
}

# allows the programmer to popup the listbox if auto-popup is disabled
sub popup {
    my $self = shift;
    my $current_word = shift; # optional, introduced with multi-matching
    $self->{selected} = 0;
    $self->open_listbox($current_word);
}

# hide/unhide the popup listbox
sub open_listbox {
    my $self = shift;
    my $current_word = shift; # optional, introduced with multi-matching

    # check whether we are in state "disabled"
    return if ($self->cget('-state') eq 'disabled');

    if ($self->{'popped'}) {
        $self->close_listbox;
    }
    else {
        $self->show_listbox($current_word);
    }
}

# Remove all entries from the choices listbox which can't match the user's
# input anymore.
sub listbox_filter {
    my $self = shift;
    my $text_to_match = shift; # optional, introduced with multimatching
    
    my $listbox = $self->Subwidget('slistbox')->Subwidget('listbox');
    my $entry = $self->Subwidget('entry');

    $entry->update;
    my $cursor_pos = $entry->index('insert');

    my $old_index = $self->listbox_index;
    my ($old_value, $new_index);
    if (defined $old_index) {
        $old_value = $listbox->get($old_index);
    }
    $listbox->delete(0, 'end');
    my $ignore_case = ($self->cget(-case) ? "(?i)" : "");
    my $all_choices_r = $self->{Configure}{all_choices_r};
    my @all_choices = @$all_choices_r;
 
    my $text = $entry->get;
    (my $typed_text = $text) =~ s/^(.{$cursor_pos})(.*)/$1/;
    my $rest_of_line = $2;

    my $prefix = $self->cget(-matchprefix) || "";        

    my $force_match = '';
    if (length $self->{Configure}{last_user_input}) {
        $force_match = $self->{Configure}{last_user_input};
    }
    
    unless (defined $text_to_match) {
        if ($rest_of_line ne "") { # text after cursor
            # only use matching if whole text matches one of the choices
            my $text_is_choice = 0;

            foreach my $choice (@all_choices) {
                if ($text =~ m/^${ignore_case}\Q$choice\E$/) {
                    $text_is_choice++;
                }
            }

            # give it a try for sure if we have a match-prefix
            $self->{Configure}{last_filter_matched_by_prefix_only} = 0;
            if ($text_is_choice == 0) {
                if (length $prefix) {
                    $self->{Configure}{last_filter_matched_by_prefix_only} = 1;
                    $text_is_choice++;
                }
            }

            return unless ($text_is_choice);
        }
    } 
    else { # multimatch mode or $text_to_match otherwise specified
        # print "text to match: $text_to_match\n";
        $typed_text = $text_to_match;

        if (length $typed_text) {
            # check whether the text typed by the user can match
            # any of the choices,
            # a) as it is
            # b) at least with the match-prefix
            my $text_is_choice = 0;
            foreach my $choice (@all_choices) {
                if ($choice =~ m/^${ignore_case}\Q$typed_text\E/) {
                    $text_is_choice++;
                }
            }
            # give it a try for sure if we have a match-prefix
            $self->{Configure}{last_filter_matched_by_prefix_only} = 0;
            if ($text_is_choice == 0) {
                if (length $prefix) {
                    $self->{Configure}{last_filter_matched_by_prefix_only} = 1;
                    $text_is_choice++;
                }
            }
        }
    }

    if ($self->{Configure}{last_filter_matched_by_prefix_only}) {
        $self->{Configure}{last_user_input} = $typed_text;
    }
    else {
        $self->{Configure}{last_user_input} = '';
    }
    
    # print "real input: . " . $self->{Configure}{was_real_input} . "\n";
    
    if (length $force_match) {
        $typed_text = $force_match
            unless($self->{Configure}{was_real_input});
        $self->{Configure}{last_user_input} = $typed_text
            unless($self->{Configure}{was_real_input});
    }
    
    my $index = 0;
    foreach my $choice (@all_choices) { # @all_choices is sorted
        if ($choice =~ m/^${ignore_case}$prefix\Q$typed_text\E/) {    
            $listbox->insert('end', $choice);
            if (defined $old_value && ($old_value eq $choice)) {
                $new_index = $index;
            }
            $index++;
        }
    }

    if (defined $new_index) {
        # $listbox->see($new_index);
        $listbox->selectionSet($new_index);
        $listbox->activate($new_index);
    }
    
    $self->{Configure}{last_number_of_entries} = $index;
    return $index; # equals number of visible elements
}

# Display the listbox
sub show_listbox {
    my $self = shift;
    my $current_word = shift; # optional

    # Don't do that stuff if we're already popped up
    unless ($self->{'popped'}) {
        # Allow the programmer to change his choices
        $self->Callback(-listcmd => $self); 

        # Display only listbox entries which could match
        my $number_of_visible_elements = $self->listbox_filter($current_word);
        
        # abort if listbox would be empty or contain less entries
        # than required for auto-completion (usually 1)
        return unless (defined $number_of_visible_elements &&
        #    ($number_of_visible_elements > $self->cget(-complete))); # kh
            ($number_of_visible_elements > 0));                       # kh
        
        # Fetch our subwidgets
        my $entry = $self->Subwidget('entry');
        my $choices = $self->Subwidget('choices');
        my $scrolled_listbox = $self->Subwidget('slistbox');

        # Calculate height and width for the popup listbox
        my $y1 = $entry->rooty + $entry->height + 3;
        my $bd = $choices->cget(-bd) + $choices->cget(-highlightthickness);
        #my $ht = ($scrolled_listbox->reqheight / 2) + 2 * $bd + 2;

        # Calculate height for listbox. Default reqheight = 10 elements.
        my $maxheight = $self->cget(-maxheight);
        
        my $elements_per_page = 
            $number_of_visible_elements < $maxheight ?
            $number_of_visible_elements : $maxheight;
            
        my $ht = (($scrolled_listbox->reqheight * 
                 $elements_per_page) / 10) + 2 * $bd + 2;
                
        my $x1 = $entry->rootx + $bd + 3;

        # Check whether the scrollbar should be hidden
        if ($number_of_visible_elements <= $maxheight) { # hide it
            $scrolled_listbox->configure(-scrollbars => '');
        } 
        else { # show the scrollbar
            $scrolled_listbox->configure(-scrollbars => 'oe');
        }
        
        my ($width, $x2);
        # Check whether programmer has specified a width
        $width = $self->cget(-listwidth);
        if (defined $width) {
            $x2 = $x1 + $width;
        } # else take the entry widget's width
        else {
            $x2 = $entry->rootx + $entry->width;
            $width = $x2 - $x1;
            $width = 1.5 * $width
        }

        # check requested and maximum width unless programmer forbid
        my $rw = $choices->reqwidth;
        unless ($self->cget(-fixedwidth)) {
            if ($rw < $width) {
                $rw = $width;
            }
            else {
                if ($rw > $width * 3) {
                    $rw = $width * 3;
                }
                if ($rw > $self->vrootwidth) {
                    $rw = $self->vrootwidth;
                }
            }
            $width = $rw;
        }
        else { # force fixed width
            $rw = $width;
        }

        # check whether listbox is too far right
        if ($x2 > $self->vrootwidth) {
            $x1 = $self->vrootwidth - $width;
        }

        # check whetherlistbox is too far left
        if ($x1 < 0) {
            $x1 = 0;
        }

        # check whether listbox is below bottom of screen
        my $y2 = $y1 + $ht;
        if ($y2 > $self->vrootheight) {
            $y1 = $y1 - $ht - ($entry->height - 5);
        }
                
        # Set the listbox's geometry and show it
        $choices->geometry(sprintf('%dx%d+%d+%d', $rw, $ht, $x1, $y1));
        $choices->deiconify;
        $choices->raise;
        $entry->focus;
        $self->{'popped'} = 1;

        $choices->configure(-cursor => 'arrow');
        
        $self->{selected} = 0;
        $scrolled_listbox->selection('clear', 0, 'end');
        
        #$self->grabGlobal;
    }
}

# close the popup listbox
sub close_listbox {
    my ($self) = @_;
    # clearing the selection is Tk::BrowseEntry's behavior when pressing
    # <Escape>. However, it seems to be more useful here to leave the
    # selection as it is.

    $self->{selected} = 0;

    my $listbox = $self->Subwidget('slistbox')->Subwidget('listbox');
    $listbox->selection('clear', 0, 'end');
    $self->hide_listbox;
}

# called to select a listbox entry
sub choose_listbox {
    my ($self, $x, $y) = @_;
    
    return unless($self->{'popped'});
    
    my $listbox = $self->Subwidget('slistbox')->Subwidget('listbox');
    # check whether the user clicked outside
    if ( ($x < 0) ||
         ($y < 0) ||
         ($x > $listbox->Width) ||
         ($y > $listbox->Height) ) {
         $self->close_listbox;
    }
    else { # some entry was clicked on
        $self->copy_selection_listbox;
        $self->Callback(-browsecmd => $self, $self->Subwidget('entry')->get);
    }
}

# Copy the selection to the entry widget and close the listbox
sub copy_selection_listbox {
    my ($self) = @_;
    #$self->listbox_copy_to_entry;
    $self->listbox_invoke;
    $self->hide_listbox;
}

sub listbox_invoke{
    my ($self) = @_;
    return unless ($self->{popped});
    return unless ($self->{selected});
    my $index = $self->listbox_index;
    if (defined $index) {
        my $listbox = $self->Subwidget('slistbox')->Subwidget('listbox');
        my $t = $listbox->get($index);
        
        $self->{invoke} = $t;
        $self->Callback(-invcmd => $self);
    }
}

# Copy the currently selected listbox item to the entry widget
sub listbox_copy_to_entry {
    my ($self) = @_;
    return unless ($self->{'popped'});
    my $index = $self->listbox_index;
    if (defined $index) {
        $self->{'curIndex'} = $index;
        my $listbox = $self->Subwidget('slistbox')->Subwidget('listbox');
        my $var_ref = $self->cget('-textvariable');
    
        if ($self->cget(-multimatch)) {
            my $entry = $self->Subwidget('entry');

            my $pos = $entry->index('insert');
            my $text = $entry->get; 
            if ($text =~ m/^(.{$pos})(.*)/) {
                my $text_before = $1;
                my $text_behind = $2;

                if ($text_before =~ m/\s/) {
                    $text_before =~ s/(.*)\s.*/$1/;
                }
                else {
                    $text_before = "";
                }

                if ($text_behind =~ m/\s/) {
                    $text_behind =~ s/.*?\s(.*)/$1/;
                }
                else {
                    $text_behind = "";
                }
                
                my $newvalue;
                $newvalue .= $text_before . " " if (length $text_before);
                $newvalue .= $listbox->get($index);
                $newvalue .= " " . $text_behind if (length $text_behind);

                $$var_ref = $newvalue;
                $entry->icursor($pos); # ?
            }
        } 
        else {
            $$var_ref = $listbox->get($index);
        }
    }
}

# Return the index of the currently selected listbox item
sub listbox_index {
    my ($self, $flag) = @_;
    my @sel = $self->Subwidget('slistbox')->Subwidget('listbox')->curselection;
    my $sel;
    if (defined($sel[0])) {
        $sel = $sel[0];
    }
    else {
        # undef $sel;
    }
    if (defined $sel) {
        return int($sel);
    }
    else {
        if (defined $flag && ($flag eq 'emptyOK')) {
            return undef;
        }
        else {
            return 0;
        }
    }
}

# hide the popup listbox
sub hide_listbox {
    my ($self) = @_;
    if ($self->{'savefocus'} && Tk::Exists($self->{'savefocus'})) {
        $self->{'savefocus'}->focus;
        delete $self->{'savefocus'};
    }
    if ($self->{'popped'}) {
        my $choices = $self->Subwidget('choices');
        $choices->withdraw;
        $self->grabRelease;
        $self->{'popped'} = 0;
    }
}

# User pressed <Return> in the listbox
sub return_listbox {
    print "return_listbox 0\n";
    my ($self, $listbox) = @_;
    my @sel = $self->Subwidget('slistbox')->Subwidget('listbox')->curselection;
    my $sel;
    $sel = $sel[0] if (defined($sel[0]));
    return unless (defined($sel));
    print "return_listbox 1\n";
    
    my ($x, $y) = $listbox->bbox($sel);
    $self->choose_listbox($x, $y);
    print "return_listbox 2\n";

    # place insert cursor at end of entry widget
    $self->Subwidget('entry')->icursor('end');
    print "return_listbox 3\n";
}

# User pressed <Tab> in the listbox
sub listbox_tab {
    my ($self, $listbox) = @_;
    $self->return_listbox($listbox);
}

# Lets the programmer get/set the choices array
sub choices {
    my ($self, $choices) = @_;
    $self->{selected} = 0;

    if (@_ > 1) { # set them
        # remember all the possible choices given by the programmer
        if ($self->cget(-autosort)) {
            my @c = @$choices;
            my @all_choices = $self->Callback(-sortcmd => \@c) || 
                              sort @c;
            $self->{Configure}{all_choices_r} = \@all_choices;
        }
        else {
            my @unsorted_choices = @$choices;
            $self->{Configure}{all_choices_r} = \@unsorted_choices;
        }
    }
    else { # get them
        return ($self->get(qw/0 end/));
    }       
}

sub resort {
    my $self = shift;

    my $all_choices_r = $self->{Configure}{all_choices_r};
    my @choices = @$all_choices_r;
 
    my $nocallback = 0;
    $self->{Configure}{all_choices_r} = 
            $self->Callback(-sortcmd => \@choices) or $nocallback = 1;

    if ($nocallback) {
        my @sorted_choices = sort @choices;
        $self->{Configure}{all_choices_r} = \@sorted_choices;
    }
}

# Lets the programmer get/set the widget's state
sub state {
    my $self = shift;

    unless (@_) {
        return ($self->{Configure}{-state});
    }
    else {
        my $state = shift;
        $self->{Configure}{-state} = $state;
        $self->_set_edit_state($state);
    }
}

# Set the edit state internally
sub _set_edit_state {
    my ($self, $state) = @_;
    my $entry = $self->Subwidget('entry');

    if ($self->cget('-colorstate')) {
        my $color;
        if ($state eq 'normal') { # editable
            $color = 'gray95';
        }
        else { # not editable
            $color = $self->cget(-background) || 'lightgray';
        }
        $entry->Subwidget('entry')->configure(-background => $color);
    }

    if ($state eq 'readonly') {
        $entry->configure(-state => 'disabled');
    }
    else {
        $entry->configure(-state => $state);
    }
}

# return success
1;

__END__

=pod 

=head1 NAME

Tk::MatchEntry - Entry widget with advanced auto-completion capability

=head1 SYNOPSIS

    use Tk::MatchEntry;
    
    my $match_entry = $top->MatchEntry(
        -textvariable => \$var1, 
        -choices => \@choices,
    );

=head1 DESCRIPTION

C<Tk::MatchEntry> is an Entry widget with focus on user-friendly
auto-completion. Its usage is similar to C<Tk::BrowseEntry> and
C<Tk::HistEntry>. 

With each character the user types in the widget, automatic completion
can be attempted based on a list of B<choices> you as programmer specify.

If there's more than one of the B<choices> matching the text which the user
has entered so far, she can optionally select the desired auto-completion
choice from an up-popping listbox, either by using the mouse or by browsing 
them with the B<Up> and B<Down> cursor keys. 

This listbox with auto-completion choices pops up automatically by 
default and only shows these B<choices> which still can match the manually 
entered text, i.e. the number of displayed items usually decreases with the 
length of text entered by the user.

The auto-completed part of the text in the Entry widget always gets 
selected so the next manually entered character overwrites it. Thus, 
the auto-completion feature never prevents the user from typing 
what she really wants to.

Starting with version 0.2, C<Tk::MatchEntry> has a multi-match mode in which 
each word the user types can be auto-completed. For example, if you've got the
four B<choices> I<Another>, I<Hacker>, I<Just> and I<Perl>, the user can write
I<Just Another Perl Hacker> for example by hitting J, Return, A, Return, P, 
Return, H, Return.

=head1 OPTIONS

Besides the options which can be applied to the C<entry> and C<slistbox>
subwidgets, C<MatchEntry> provides the following specific options:

=over 4

=item B<-textvariable> or B<-variable>

The variable which is tied to the MatchEntry widget. B<-variable>, as
used in BrowseEntry, is just an alias for B<-textvariable>. This variable
will contain the entry widget's text.

=item B<-choices>

Array of strings which the auto-completion feature attempts to match. 
Used the same way as in C<Tk::BrowseEntry>. 

=item B<-complete>

If set to a true value, auto-completion is attempted whenever the user
enters another character in the widget. This is what C<Tk::MatchEntry> 
is all about, so it defaults to 1. Auto-completion is hopefully smart 
enough to know what the user wants to do and doesn't mess up the text 
she's entering.

=item B<-ignorecase>

If not false, auto-completion works case-insensitive. Thus, if you
have a choice C<John Doe> and the user starts with a C<j>, auto-completion
will be C<john Doe>. However, if auto-completion is set to case-insensitivity
AND the text in the entry widget matches one of the B<choices> when the
MatchEntry widget is left, the text will be replaced by the B<choice>, i.e.
in our example, C<john Doe> would turn into C<John Doe>. Defaults to 0.

=item B<-autopopup>

If set to a true value, the listbox with auto-completion choices
will automatically pop up if the user has entered at least one
character in the widget yet AND there's at least two possible
choices. Defaults to 1.

=item B<-maxheight>

Sets the maximum number of entries per page in the (scrolled) popup 
listbox with auto-completion choices. Defaults to 5.

=item B<-autoshrink>

If set to a true value, the popup listbox's height will decrease
if there's less than B<-maxheight> items to display. For example,
if B<-maxheight> is set to 5, but there's only 3 choices, and
B<-autoshrink> is set to 1, then the listbox will show only those
3 choices instead of the 3 choices plus two empty rows.

=item B<-fixedwidth>

If set to a true value, the popup listbox will always have the same
width as the entry widget. Otherwise, the width of the listbox is
calculated the same way as in C<Tk::BrowseEntry>. Defaults to 1.

=item B<-listwidth>

If B<-fixedwidth> is set to 0, B<-listwidth> can be used to specify
the popup listbox's width.

=item B<-multimatch>

When set to a true value, the multi-match mode is activated. In
regular mode, C<Tk::MatchEntry> attempts to match and auto-complete
the whole text in the entry widget. In multi-match mode, it does
the same for each word the user enters. Don't use this unless you're
sure that's what you want. When using multi-match mode, the B<choices>
should be single words (as opposed to phrases, i.e. multiple 
blank-separated words). Defaults to 0.

=item B<-autosort>

When set to a true value, the B<choices> are automatically sorted,
either when set through -choices in the B<new> method or through the
B<choices> method. Sorting is done with Perl's built-in B<sort>
function unless you've specified a B<-sortcmd> callback.
Defaults to 1.

=item B<-sorttrigger>

Useful in multi-match mode when using a custom B<-sortcmd> callback
which sorts the B<choices> based on what the user has entered so far.
B<-sorttrigger> is a regular expression; if it matches against the
user's latest pressed key, then the B<resort> method is called.
The B<-sortcmd> callback can then be used to add words entered by the
user to the list of choices, sort them by usage frequency, etc.

The value of this option defaults to B<undef> and you should only
change it if you know what you're doing: both matching this regular
expression against each key pressed by the user and unnecessarily
often calling B<resort> can decrease performance.

Example usage:

 ...
 -sorttrigger => '^Left|^Right|^space|^Home|^End',
 ...
 
(The lower case s in I<^space> is actually not a typo)

=item B<-matchprefix>

Using a match prefix allows lazy typing on your user's side. It's best
explained by comparing it to the field where you enter a URL in modern
web browsers. Let's say you have a choice

 http://www.cpan.org

and you would like to allow the user typing either of these:

 http://www.cpan.org
 www.cpan.org
 cpan.org

while still getting the benefits of auto-completion and the up-popping 
choices listbox, then you should set B<-matchprefix> to

 '(?:http:\/\/)?(?:www\.)?'

In fact, B<-matchprefix> is a regular expression which B<must> fulfill
the following criteria:

1) You B<must> use non-capturing brackets if you're using grouping.
That's why we use 

 (?:http:\/\/)?

in the above example and B<NOT>

 (http:\/\/)?

2) Prefix matches B<must> be optional, i.e. you always should use 
the ? quantifier (using * would work, too, but might be bad for 
performance).

Here's another example for matching HTTP and FTP URLs like in the above
example, i.e. both the I<http://> and I<www.> parts are optional.

 ...
 -matchprefix => '(?:(?:ftp|http):\/\/)?(?:(?:ftp|www)\.)?',
 ...

=item B<-wraparound>

If set to a true value, then the selection in the popup listbox will
wrap around to the first entry if the user presses the down cursor key
at the very bottom of the listbox. Also, the last entry in the listbox 
will be selected after pressing cursor-up while having the first
listbox entry selected. Defaults to 0.
 
=back

The following options specify callbacks:

=over 4

=item B<-listcmd>

Executed when the listbox is about to be popped up. This is a 
good place for changes to the B<-choices>.

=item B<-entercmd>

Executed when the user hits the B<Return> key.

=item B<-tabcmd>

Executed when the user hits the B<Tab> key.

=item B<-zerocmd>

Executed when the insert cursor moves back to position 0 in the
entry widget (see B<-onecmd>).

=item B<-onecmd>

Executed when the insert cursor moves to position 1 in the entry widget
(i.e. after the first character).

B<-zerocmd> and B<-onecmd> are supposed to be used together in
applications where you want totally different B<choices> depending
on whether the user has already entered any text yet. For example,
if a MatchEntry widget is used for the recipient's name in an email
client, the choices

a) when the user has not entered anything yet could be the names
of the 10 last persons he had sent an email to.

b) after entering the first character could be appropriate names 
from his address book.

=item B<-command> or B<-browsecmd>

Executed when the user has selected an entry from the auto-completion 
popup-listbox. Provided for compatibility with C<Tk::BrowseEntry>.

=item B<-mm_zerocmd> and B<-mm_onecmd>

Same as B<-zerocmd> and B<-onecmd>, additionally called in B<multimatch>
mode if the current word's length is 0, or 1 respectively.

=item B<-sortcmd>

Callback used to sort the array of B<choices>. If you don't specify
this callback, Perl's internal B<sort> function will be used to
sort the B<choices> alphabetically unless B<autosort> is turned off.

A reference to the array of choices is passed to the custom sorting 
function and it must return a reference to the sorted array.

Trivial example:

 sub mysort {
     my $ref = shift;
     my @choices = @$ref;
     my @sorted_choices = sort @choices;
     return \@sorted_choices;
 }

You can abuse this callback to insert or delete choices while sorting
them. Normally, the standard B<choices> method is used to update the
choices array, of course.

=item B<-bottomcmd>

Called when the user presses the cursor-down key if the bottom
entry in the popup listbox was already selected. Can be used for 
accoustic signals etc. Called even if B<-wraparound> is true.

=item B<-topcmd>

Same as B<-bottomcmd> but called when the user presses the cursor-up key
if already at the first entry of the popup listbox.

=back

=head1 METHODS

=over 4

=item B<popup>

Pops the auto-completion listbox up if there are enough possible
choices. This should only be used if B<-autopopup> is set to 0.
As C<Tk::MatchEntry> does, compared to C<Tk::BrowseEntry> and
C<Tk::HistEntry>, I<not> provide an arrow button for popping up the
listbox, you might want to use a button of your own for this
purpose.

If the listbox is already open, calling this method closes it.

=item B<choices>

If called with no parameter, this returns an array containing the current
B<choices>.

If given an array as parameter, it will set the B<choices>. Unless
B<autosort> is turned off, the choices will be sorted automatically,
either using Perl's built-in B<sort> function or the B<-sortcmd> callback
you've specified. 

=item B<resort>

Enforces re-sorting the array of choices, either using Perl's built-in
B<sort> function or the B<-sortcmd> callback if you've specified one.
Useful if B<autosort> is turned off or your custom B<-sortcmd> wants
to take into account what the user has entered so far, for instance
to sort the choices by their usage frequency in multi-match mode.

=back

=head1 KEY BINDINGS

=over 4

=item B<Up>, B<Down>

Navigates through the auto-completion listbox. Forces the listbox
to pop up when used at entry widget cursor position 0 if there are
any choices to display. 

=item B<Tab>, B<Return>

Accepts the currently suggested or selected auto-completion. The
insert cursor will be placed at the end of the entry widget. The
callback B<-tabcmd> or B<-entercmd> will be executed.

=item B<Escape>

Pressed once it closes the auto-completion listbox if it's open.
On pressing it twice the currently auto-completed text will be erased.
For example, if you have a choice C<John Doe>, but the user just wants
to enter C<John>, she actually has to press B<Escape> (or B<Delete>)
to remove the auto-completed C< Doe> part.

=back

=head1 NOTES

If you need to configure the subwidgets, for example to set different
background colors for the entry and the listbox widget, you can access 
them like this:

 my $entry_subwidget = $matchentry->Subwidget('entry');

 my $listbox_subwidget = 
    $matchentry->Subwidget('slistbox')->Subwidget('listbox');

C<slistbox> is the C<scrolled> listbox.
    
=head1 BUGS

=over 4

=item Execution of the -browsecmd callback needs improvement.

=back

=head1 EXAMPLES

This is a primitive example for Tk::MatchEntry which you can use to get to
know the look and feel.

    use Tk;
    use Tk::MatchEntry;
    
    my $mw = MainWindow->new(-title => "MatchEntry Test");
    
    my @choices = ( qw/one one.green one.blue one.yellow two.blue two.green
                    two.cyan three.red three.white three.yellow/ );
    
    $mw->Button->pack(-side => 'left');

    my $me = $mw->MatchEntry(
        -choices        => \@choices,
        -fixedwidth     => 1, 
        -ignorecase     => 1,
        -maxheight      => 5,
        -entercmd       => sub { print "callback: -entercmd\n"; }, 
        -onecmd         => sub { print "callback: -onecmd  \n"; }, 
        -tabcmd         => sub { print "callback: -tabcmd  \n"; }, 
        -zerocmd        => sub { print "callback: -zerocmd \n"; },
    )->pack(-side => 'left', -padx => 50);
    
    $mw->Button(
        -text => 'popup', 
        -command => sub{$me->popup}
    )->pack(-side => 'left');
 
 MainLoop;

=head1 AUTHOR

Wolfgang Hommel <wolf (at) code-wizards.com>

=head1 SEE ALSO

The following widgets are similar to I<Tk::MatchEntry> to a certain extent:

=over 4

=item L<Tk::BrowseEntry>

=item L<Tk::HistEntry> 

=item L<Tk::JBrowseEntry>

=back

=head1 CREDITS

Thanks to 

=over 4

=item Slaven Rezic for I<Tk::HistEntry>. Some of the auto-completion ideas are 
based on it.

=item Jesse Farinacci for suggesting, specifying and testing the multimatch 
mode.

=item Ingo Herschmann for bug reports and patches.

=back

=head1 COPYRIGHT

Copyright (c) 2003 - 2020 Wolfgang Hommel. All rights reserved.

This package is free software; you can redistribute it and/or modifiy
it under the same terms as Perl itself.

=cut
