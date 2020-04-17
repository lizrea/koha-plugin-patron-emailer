package Koha::Plugin::Com::ByWaterSolutions::PatronEmailer;

## It's good practice to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

use File::Basename;
use DateTime;
use Text::CSV;
use Koha::Database;
use Koha::Notice::Templates;
use Koha::Patrons;
use Koha::Reports;
use List::Util qw( any );
use C4::Reports::Guided qw( execute_query );

use Template;
use utf8;

use open qw(:utf8);

## Here we set our plugin version
our $VERSION = 2.00;

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name            => 'Patron Emailer',
    author          => 'Kyle M Hall',
    description     => 'This plugin takes a Koha patrons file and sends an email to the patrons found in the file',
    date_authored   => '2015-06-18',
    date_updated    => '2015-06-18',
    minimum_version => '3.1800000',
    maximum_version => undef,
    version         => $VERSION,
};

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

## The existance of a 'tool' subroutine means the plugin is capable
## of running a tool. The difference between a tool and a report is
## primarily semantic, but in general any plugin that modifies the
## Koha database should be considered a tool
sub tool {
    my ( $self, $args ) = @_;

    my $cgi = $self->{'cgi'};

    if ( $cgi->param('patrons') || $cgi->param('report_id') ) {
        $self->tool_step2();
    }
    elsif ( $cgi->param('step3') ){
        $self->tool_step3();
    } else {
        $self->tool_step1();
    }

}

## This is the 'install' method. Any database tables or other setup that should
## be done when the plugin if first installed should be executed in this method.
## The installation method should always return true if the installation succeeded
## or false if it failed.
sub install() {
    my ( $self, $args ) = @_;

    return 1;
}

## This method will be run just before the plugin files are deleted
## when a plugin is uninstalled. It is good practice to clean up
## after ourselves!
sub uninstall() {
    my ( $self, $args ) = @_;

    return 1;
}

sub tool_step1 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template( { file => 'tool-step1.tt' } );
    my $letters = Koha::Notice::Templates->search( {}, { order_by=>['me.branchcode','me.module','me.name'] } );
    my $subject = $self->retrieve_data('subject');
    $template->param( letters => $letters, subject => $subject );

    print $cgi->header("text/html;charset=UTF-8");
    print $template->output();
}

sub tool_step2 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};
    my $template = $self->get_template( { file => 'tool-step2.tt' } );


    my ( $body_template, $subject, $letter_code, $is_html );
    if( $cgi->param('use_built_in') ){
        $body_template = $self->retrieve_data('body');
        $subject       = $self->retrieve_data('subject');
        $is_html       = $self->retrieve_data('is_html');
        $letter_code   = "BUILT_IN";
    } else {
        my $branchcode = $cgi->param("branchcode");
        my $module = $cgi->param("module");
        my $letter = $cgi->param("letter");
        warn " $branchcode and $module and $letter ";
        my $notice = Koha::Notice::Templates->find({ branchcode => $branchcode, module => $module, code => $letter });
        $body_template = $notice->content;
        $subject       = $notice->title;
        $letter_code   = $notice->code;
        $is_html       = $notice->is_html;
    }

    my @not_found;
    my @to_send;

    my $filename = $cgi->param("patrons");
    if( $filename ){
        my ( $name, $path, $extension ) = fileparse( $filename, '.csv' );

        my $csv_contents;
        open my $fh_out, '>', \$csv_contents or die "Can't open variable: $!";

        my $delimiter = $self->retrieve_data('delimiter');
        my $csv = Text::CSV->new( { binary => 1, sep_char => $delimiter } )
          or die "Cannot use CSV: " . Text::CSV->error_diag();

        my $upload_dir        = '/tmp';
        my $upload_filehandle = $cgi->upload("patrons");
        open( UPLOADFILE, '>', "$upload_dir/$filename" ) or die "$!";
        binmode UPLOADFILE;
        while (<$upload_filehandle>) {
            print UPLOADFILE;
        }
        close UPLOADFILE;
        open my $fh_in, '<', "$upload_dir/$filename" or die "Can't open variable: $!";

        my $column_names = $csv->getline($fh_in);
        unless( any { $_ eq 'cardnumber' } @$column_names ){
            close $fh_in;
            $template->param( no_cardnumber => 1 );
            print $cgi->header("text/html;charset=UTF-8");
            print $template->output();
            return;
        }
        $csv->column_names(@$column_names);

        while ( my $hr = $csv->getline_hr($fh_in) ) {
            my $email = generate_email($hr, $body_template,$subject);
            if( $email ){
                push @to_send, $email;
            } else {
                push @not_found, $hr->{cardnumber};
            }
        }
        $csv->eof or $csv->error_diag();
        close $fh_in;

    } else {
        my $report_id = $cgi->param("report_id");
        my $report = Koha::Reports->find( $report_id );
        my $sql = $report->savedsql;
        my ( $sth, $errors ) = execute_query( $sql ); #don't pass offset or limit, hardcoded limit of 999,999 will be used
        while ( my $row = $sth->fetchrow_hashref() ) {
            unless( defined $row->{'cardnumber'} ){
                $template->param( no_cardnumber => 1 );
                print $cgi->header("text/html;charset=UTF-8");
                print $template->output();
                return;
            }
            my $email = generate_email($row, $body_template,$subject);
            if( $email ){
                push @to_send, $email;
            } else {
                push @not_found, $row->{cardnumber};
            }
        }
    }


    $template->param(
        not_found => \@not_found,
        sent      => \@to_send,
        is_html   => $is_html,
        letter_code => 'PEP_' . $letter_code,
    );

    print $cgi->header("text/html;charset=UTF-8");
    print $template->output();
}

sub generate_email {
    my $line = shift;
    my $body_template = shift;
    my $subject = shift;

    my $template = Template->new({ENCODING => 'utf8'});

    my $body;
    $template->process( \$body_template, $line, \$body );

    my $borrower = Koha::Patrons->find( { cardnumber => $line->{cardnumber} } );
    return unless $borrower;

    my $prepped_email =
        {
            borrowernumber         => $borrower->borrowernumber(),
            subject                => $subject,
            content                => $body,
            message_transport_type => 'email',
            status                 => 'pending',
            to_address             => $line->{email},
            from_address           => $line->{from} || C4::Context->preference('KohaAdminEmailAddress'),
         };
    return $prepped_email;
}

sub tool_step3 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};
    my $template = $self->get_template( { file => 'tool-step3.tt' } );
    my @borrowernumber = $cgi->multi_param('borrowernumber');
    my @subject= $cgi->multi_param('subject');
    my @content = $cgi->multi_param('content');
    my @to_address = $cgi->multi_param('to_address');
    my @from_address = $cgi->multi_param('from_address');
    my $schema           = Koha::Database->new()->schema();
    my $message_queue_rs = $schema->resultset('MessageQueue');
    my $letter_code = $cgi->param('letter_code');
    my $is_html = $cgi->param('is_html');
    for( my $i = 0; $i < @borrowernumber; $i++ ){
        $message_queue_rs->create({
            borrowernumber => $borrowernumber[$i],
            subject => $subject[$i],
            content => $is_html ? _wrap_html($content[$i],$subject[$i]) : $content[$i],
            message_transport_type => $to_address[$i] ne "" ? 'email' : 'print',
            status => 'pending',
            to_address => $to_address[$i],
            from_address => $from_address[$i],
            letter_code => $letter_code || 'PEP'
        });

    }
    $template->param( sent => 1 );
    print $cgi->header("text/html;charset=UTF-8");
    print $template->output();
}

## If your tool is complicated enough to needs it's own setting/configuration
## you will want to add a 'configure' method to your plugin like so.
## Here I am throwing all the logic into the 'configure' method, but it could
## be split up like the 'report' method is.
sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template( { file => 'configure.tt' } );
        my $delimiter = $self->retrieve_data('delimiter');
        $delimiter = ',' if( ! defined($delimiter) || ! $delimiter );

        ## Grab the values we already have for our settings, if any exist
        $template->param( body      => $self->retrieve_data('body'), );
        $template->param( subject   => $self->retrieve_data('subject'), );
        $template->param( is_html   => $self->retrieve_data('is_html'), );
        $template->param( delimiter => $delimiter, );

        print $cgi->header("text/html;charset=UTF-8");
        print $template->output();
    }
    else {
        $self->store_data(
            {
                body               => $cgi->param('body')|| "",
                subject            => $cgi->param('subject') || "",
                delimiter          => $cgi->param('delimiter') || "",
                is_html            => $cgi->param('is_html') || "",
                last_configured_by => C4::Context->userenv->{'number'},
            }
        );
    }

    $self->go_home();
}

sub _wrap_html {
    my ($content, $title) = @_;

    my $css = C4::Context->preference("NoticeCSS") || '';
    $css = qq{<link rel="stylesheet" type="text/css" href="$css">} if $css;
    return <<EOS;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="en" xml:lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>$title</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
$css
</head>
<body>
$content
</body>
</html>
EOS
}



1;
