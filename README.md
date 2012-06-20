templates-aeolusproject
=======================


TODO
----
* Checking if the routes are correct
* More structured views
* Write the test cases
* Some other thing

Run
---
The application it's using bundler so when you're check out the code, you should run:

    $ bundle install

in order to download all the needed gems.


Since, it's a rack application to execute it, just run on your terminal :

    $ rackup

Due to the authentication dependencies, you also will need the environmental parameters like
    <table>
        <tr>
         <td>
          TWITTER_SECRET
         </td>
         <td>
          TWITTER_KEY
         </td>
        </tr>
        <tr>
         <td>
          GITHUB_SECRET
         </td>
         <td>
          GITHUB_KEY
         </td>
        </tr>
        <tr>
         <td>
          FACEBOOK_SECRET
         </td>
         <td>
          FACEBOOK_KEY
         </td>
        </tr>
     </table>


Example:
--------

An easy example mostly used in development is to define the env variables on the command line in
order to test it with different providers:

   $ TWITTER_SECRET="0edeadb33f" TWITTER_KEY="013370dEadbeef80238" rackup
