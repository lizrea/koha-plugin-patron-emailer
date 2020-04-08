This plugin takes a csv file containing patron information or a koha report and sends emails to the patrons based on the fields in the data.

You can choose to specify a template in the tool configuration or use an existing Koha notice.

The plugin will record the letter code in the database as "PEP\_" + letter code  or "PEP_BUILT_IN" for a notice specified in the tool

The CSV file must 

- Start with a header line which names the columns used
- Contain a column titled `cardnumber` containing the card numbers of the patrons to be emailed.
- Contain a column titled `email` containing the email addresses to be emailed ( if a patron has no email the letter will be queued as a print notice'

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
 * Browse to More->Tools->Tool plugins
 * Click Actions -> Configure 
 * Ensure the message is setup as you wish
 * Click Actions -> Run 
 * Upload the CSV file you saved in step 2

