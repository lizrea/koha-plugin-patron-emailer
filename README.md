This plugin takes a csv file containing patron information, and sends emails to the patrons based on the fields in the CSV file and a template specified in the tool configuration.

The CSV file must 

- Start with a header line which names the columns used
- Contain a column titled `cardnumber` containing the card numbers of the patrons to be emailed.

When configuring the email, template toolkit syntax is used to display any column names in the csv file.

For example, given the file 'Mailer-Report.csv':

    cardnumber, email, firstname, surname, fines, libraryname
    10,aaron@example.com,Aaron,Spelling, 0.40, "The Spelling Schoool"
    11,donna@example.com,"Donna Karen E",Moore, 3.80, "Motivation International"
    12,bernice@example.com,Bernice,Documents, -785.00, "Sarbanes Oxley"
    13,lou@example.com,Lou,Segusi, 39.99, "Dewey Cheatem and Howe"

If you set the following email text under configuration:

    Dear [% firstname %] [% surname %],

    You have a balance of $[% fines %]

    Please pay these at [% libraryname %] 

Then click the `Run Tool` link, you will be prompted to upload `Mailer-Report.csv`, which will send an email to each borrower in the file. Make sure that the variables being expanded (e.g. `[% firstname %]`) *exactly* match the column headers.

For example, an email containing the following content would be sent to Aaron Spelling's email address: 

    Dear Aaron Spelling,

    You have a balance of $0.40

    Please pay these at The Spelling Schoool
    
# Details    
To send the emails:
* Run the desired report
* Save the results as CSV
  * Click 'Download->Comma separated text'
  * Save the file on your computer
* Run the plugin
  * Browse to More->Tools->Tool plugins ( http://xxx.xxx.bywatersolutions.com/cgi-bin/koha/plugins/plugins-home.pl?method=tool )
 * Click Actions -> Configure ( http://xxx.xxx.bywatersolutions.com/cgi-bin/koha/plugins/run.pl? class=Koha::Plugin::Com::ByWaterSolutions::PatronEmailer&method=configure )
 * Ensure the message is setup as you wish
 * Click Actions -> Run ( http://xxx.xxx.bywatersolutions.com/cgi-bin/koha/plugins/run.pl?class=Koha::Plugin::Com::ByWaterSolutions::PatronEmailer&method=tool )
 * Upload the CSV file you saved in step 2
 * You can check on the emails sent by using the report here:
   * http://xxx.xxx.bywatersolutions.com/cgi-bin/koha/reports/guided_reports.pl?reports=150&phase=Run%20this%20report
   * For example, giving the subject 'Fines are due' you can see the test I sent myself today (with your name)
   * http://xxx.xxx.bywatersolutions.com/cgi-bin/koha/reports/guided_reports.pl?reports=150&phase=Run+this+report&sql_params=Fines+are+due


