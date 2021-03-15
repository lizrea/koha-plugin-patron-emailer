package Koha::Plugin::Com::ByWaterSolutions::PatronEmailer::ApiController;

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;

use Mojo::Base 'Mojolicious::Controller';

use Digest::MD5 qw(md5_hex);

use Koha::Plugin::Com::ByWaterSolutions::PatronEmailer;

=head1 API

=head2 Class Methods

=head3 unsubscribe

Method that generates and outputs the unsubscribe unsubscribe page html

=cut

sub unsubscribe {
    my $c = shift->openapi->valid_input or return;

    my $cardnumber = $c->validation->param('cardnumber');
    my $patron_id_hash = $c->validation->param('patron_id_hash');
    my $notice_id = $c->validation->param('notice_id');
    my $unsubscribe_type = $c->validation->param('unsubscribe_type');

    my $plugin = Koha::Plugin::Com::ByWaterSolutions::PatronEmailer->new;
    my $template = $plugin->get_unsubscribe_page({ filename => 'unsubscribe.tt' });

    my $borrower = Koha::Patrons->find( { cardnumber => $cardnumber } );
    return $c->render( status => 404, text => "Patron not found" ) unless $borrower;

    $notice = Koha::Notice::Templates->find($notice_id);

    my $salt = C4::Context->config('patron_emailer_salt') || '8374892734834839';
    my $id = $borrower->id;
    my $hash = md5_hex( $salt . $id );
    my $unsubscribe_link = "$base_url/api/v1/contrib/patronemailer/patrons/unsubscribe/$patron_id_hash/$cardnumber/$notice_id";

    $template->param(
        cardnumber       => $cardnumber,
        base_url         => $base_url,
        patron_id_hash   => $patron_id_hash,
        notice_id        => $notice_id,
        unsubscribe_type => $unsubscribe_type,
    );

    return $c->render( status => 200, text => $template->output );
}

1;
