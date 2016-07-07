This plugin takes a csv file containing patron information, and sends emails to the patrons based on the fields in the CSV file and a template specified in the tool configuration.

The CSV file must 

- Start with a header line which names the columns used
- Contain a column titled `borrowernumber` containing the borrower numbers of the patrons to be emailed.

When configuring the email, template tooklit syntax is used to display any column names in the csv file.

For example, given the file 'Mailer-Report.csv':

    borrowernumber, firstname, surname, fines, libraryname
    10,Aaron,Spelling, 0.40, "The Spelling Schoool"
    11,"Donna Karen E",Moore, 3.80, "Motivation International"
    12,Bernice,Documents, -785.00, "Sarbanes Oxley"
    13,Lou,Segusi, 39.99, "Dewey Cheatem and Howe"

If you set the following email text under configuration:

    Dear [% firstname %] [%surname%],

    You have a balance of $[% fines %]

    Please pay these at [% libraryname %] 

Then click the `Run Tool` link, you will be prompted to upload `Mailer-Report.csv`, which will send an email to each borrower in the file. 

For example, an email containing the following content would be sent to Aaron Spelling's email address: 

    Dear Aaron Spelling,

    You have a balance of $0.40

    Please pay these at The Spelling Schoool

