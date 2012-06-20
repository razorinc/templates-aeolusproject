templates-aeolusproject
=======================

How it works (by Dan Macpherson)
------------

A user writes an image template and deployable for a particular application. For example, they might want to launch a base Drupal installation in EC2 using Fedora as an OS. So they write an Image Template that includes the relevant Apache and Postgres packages. They also write a Deployable Template that installs and configures Drupal (via Audrey) to an instance with httpd/db.

Then the user thinks, "Hey, I bet there are others out there who want to install Drupal in the cloud. Maybe I should share these templates with the world."

The user uploads the templates to templates.aeolusproject.org, tags them as an Image Template and Deployable Template respectively, and create an associates between the two (basically a way of signifying a relationship between an image/deployable pair that works well together).

So then, I want to create a Drupal site on a standalone instance in my own RHEV environment.

I search templates.aeolusproject.org and find someone has already created the templates I need. Perfect. (Plus I could substitute the Image template for one with a different distro if I prefer).

I use both these template in Aeolus and install Drupal on EC2. It works great!

I go back to templates.aeolusproject.org and give the template author a 5-star rating. Great job, everything went better than expected. Plus, the rating helps his Deployable Template becomes TOTM (Template of the Month).

But I also leave a comment to say, "Hey, great templates, but I think you should include a param in the deployable that allows a user to input a comma-separated list of additional modules for their Drupal installation." This way I'm helping improve the content of templates.aeolusproject.org through feedback.

Benefits
--------

templates.aeolusproject.org does a couple of cool things:

1. Encourages people to join, contribute and collaborate to the Aeolus community

2. Encourages people to experiment with Aeolus and share their results

3. Helps new users wanting to learn more about TDL/Deployable XML

4. Provides users with a library of applications to launch into their cloud (and only needing two XML files to do so)

5. Gives us a better idea of how people are using Aeolus so that we can enhance the features they like and improve the features they don't like

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
