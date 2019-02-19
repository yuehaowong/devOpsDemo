# DevOps

Setup for this unit will be a little different than what you're used to.  In order clearly show the advantages of containerized applications, we want to share the same codebase.  

So you'll only fork this repo to one partner's account.  After you've forked it, go to your forked version and find the 'Settings' tab at the top of the repo.  Select that and then select 'Collaborators and Teams'. Scroll down to the bottom and add the other partner as a Collaborator by entering their github name and setting their access to 'write'.  

### Verify Megamarkets App

Before we get started, let's just make sure that the application loads with live updates/HMR without any kind of containerization.  We won't have full functionality, as we don't have a database hooked up yet, but don't worry, we will!

1. Run `npm install`
1. Run `npm run dev:hot`

That should open up a browser window with the MegaMarkets app all set for further development.  To verify that it's working, hop over to client/styles.css and change the color of the text to something exciting.  You should see your change immediately reflected in the browser.  Yes?  Good.  No?  Send a help desk :smiley:

Now that we have our baseline application working, let's containerize it.  We'll begin by deleting the node_modules.

`rm -rf node_modules/`

**...and we'll never npm install in this directory again!** We'll be sourcing our node_modules from an image the whole team can share.

Now, let's get this app containerized.  Go ahead and open up the README-DOCKER file and get started.