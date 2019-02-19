# AWS

## Summary

[AWS](https://aws.amazon.com/) is an IaaS (Infrastructure as a Service) provider that gives us access to dozens of professional infrastructure solutions.  

## Challenges

### Part 1 - Sign up for AWS

1. Head over to the AWS console at https://aws.amazon.com/console/ and create a free AWS account.  If you're prompted to choose between professional and personal, go with personal for now.  

    *You will be asked for a credit card* but we will be staying on the **free tier** so you should not be charged as long as you follow these instructions carefully!  (There are some extensions that will incur nominal charges if you choose to complete them.)

1. Sign in to the Console and log in using the email and password you used to create your account.

    By default, your starting region will be Ohio.  You should see this on the upper right navbar once you log in.  Remember that regions are independent.  What you have in one region is not replicated in another region unless you set that up.  

    Click on the region and change it to a region closest to you geographically.  If you ever log in to AWS and don't see the configurations you expect, always check first to see if you're looking at the correct region!

### Part 2 - IAM

You are currently signed in with your root account.  This account should only be used for billing purposes and setting up your admin group.

1. #### Create an admin group

    - Create an group called `admin` and attach the `AdministratorAccess` policy to it.

1. #### Create users

    - Add both partners as users with Programmatic and Console access.

    - Provide a simple password and make sure that both users will need to change their password upon login.

    - Add both users to the `admin` group.

    - Once you've added both users, you will see a 'success' screen where you'll have the opportunity to download a .csv containing the Access Key ID and Secret Access Key for both.  

        **DOWNLOAD THIS FILE!!**  

        This will be the **only** opportunity to get your Secret Access Key. Make sure each partner makes note of their Access Key Id and Secret Access Key.

    - Apply an IAM Password Policy to create rules for IAM user passwords.

1. #### Sign in with your new admin user account

    - Sign out of your account and follow the console sign-in link in the csv to log back in with your admin user and set up your new password.

    - From the Dashboard, you can customize your sign-in link.  If you do, you'll use this new custom name as the Account Id when you log in (before you enter your username and password)

1. #### update your `aws-elasticbeanstalk-ec2-role`

    - While access control for users is managed as 'Users', access control for AWS services is managed via 'Roles'.  We're going to need to be able to access ECR from our EC2 instance, so while we're here, let's authorize!

        - Select 'Roles' from the side menu
        - Find and select `aws-elasticbeanstalk-ec2-role`
        - Attach the `AmazonEC2ContainerRegistryReadOnly` policy to this role.  

### Part 3 - Elastic Beanstalk

Great, we have an AWS account!  Let's use it.  We'll start by creating a new application with Elastic Beanstalk, which you'll find in the Services menu dropdown.

1. #### Create a new application

    - We're going to deploy the megamarkets app, so name your application appropriately

1. #### Create a production environment

    - Note that you'll have to set an environment name.  The default value is something like `megamarkets-env`.  You'll want to change that to something the easily identifies this as the production environment for the megamarkets application.

    - We're going to deploy a containerized application, so select Docker as your preconfigured platform.

    - In order to deploy your initial code, you'll need to zip it up into an archive file.  We can use git to do this.

         `git archive -v -o myMM.zip --format=zip HEAD`

    - Select `Create Environment` and wait for a few minutes while AWS creates an S3 bucket, sets up security groups and spins up your EC2 instance complete with our application running in a docker container.

    - Once this is complete, open the Dashboard for your new environment and follow the URL at the top to see your application running in the cloud.

### Part 4 - Getting CLI Access your EC2 instance
Well that wasn't too bad at all.  We've got a server running in the cloud, hosting our full stack React/Redux application.  So, how can we log into this server and check things out from the command line?

We're going to use a network protocol called SSH (Secure Shell).  This will allow us to log in to our EC2 instance across a secure channel.  We'll also be able to log in without having to enter a password.  

*Wait, a secure channel without a password?*

Yep!  SSH allows us to use a **key pair** where the server has a public key and the client has a private key.  When you set up your client with the private key, every login verifies it against the public key.  If it's a match, you're in!  

1. #### Set up your key pair
    - Go to EC2 under the Services menu and select 'Key Pairs'.
    - Create a new key pair and give it a meaningful name like 'mm-ec2-key'
    - This will create the public key and download a .pem file to your local machine.  You will want to take this file and place it in your ~/.ssh directory (create this if you don't have one already)
    - Private keys must have tight [file level security](https://www.linux.org/threads/file-permissions-chmod.4124/), so we'll change that using the linux command to 'change mode' on the file
        - `chmod 400 ~/.ssh/mm-ec2-key.pem`
    - Now let's go set up the public key on our EC2 instance.  You'll need to save the Public DNS for your EC2 instance for loggin in. You can find that under EC2 -> Instances.
    - Now go over to the Elastic Beanstalk service and open the dashboard for your production environment.
    - Select Configuration -> Security and set your mm-ec2-key up as the EC2 key pair and wait for the environment to update.
    - Now we can login to our instance from the command line by invoking ssh, providing the private key, and logging in as `ec2-user` (which is the default for new EC2 instances)
        - `ssh -i ~/.ssh/mm-ec2-key.pem ec2-user@your-ec2-public-dns`
    - To see your code
        - `cd /var/app/current/`
    - To see your server log files
        - `cd /var/log/eb-docker/containers/eb-current-app/`
    - To see them sorted by date
        - `ls -ltr`


### Part 5 - RDS

Of course, we can't do anything with the application yet.  We'll need to hook up the database first, so we've still got some work to do.

1. #### Create a new RDS instance
    - In order to create a database that isn't tied directly to the lifecycle of our Elastic Beanstalk environment, we'll go back to the Services menu and select RDS.

    - Create a PostgreSQL database.

    - Make sure to select the option to `Only enable options eligible for RDS Free Usage Tier`

    - Keep the defaults for database engine version, instance class (micro), and 20Gb of allocated storage to ensure that we stay in the free tier.  Note that you *could* set up a replica of your database in a separate Availability Zone here (but that could incur a charge).

    - Give your dbinstance a meaningful name that indicates what database it will contain and which environment it's for. Set your Master username to `mmadmin`.

    - In typical production environments, you do not make your database publicly accessible.  They should only be accessible from our EC2 server.  We'll follow that rule here.

    - Name your database `mmdb` and leave all other settings at their defaults.

    - Create Database and wait while AWS spins up your database instance. You can see the current state of the database instance if you select Databases from the side menu.

### Part 6 - Security Groups

Once your database is up and running, we'll need to make sure that your EC2 instances can communicate with it.  To do that, we'll need to edit the settings for their respective security groups.

1. #### Edit Security Group settings
    - Head over to EC2 from the Services menu and select Security Groups.  Here you'll see all of the security groups set up in your VPC (Virtual Private Cloud).
    - You should see the security group for your elastic beanstalk EC2 and the newly created security group for your RDS instance.  
    - First, tag your RDS security group with a 'Name' and set it to 'mm-db-prod-sg'.  You can also set your EC2 security group to 'mm-prod-sg'.  This will make them easier to identify in the future.
    - Let's give the EC2 instance access by creating a new inbound rule for our 'mm-db-prod-sg' security group that allows postgres traffic from our 'mm-prod-sg' security group.  

### Part 7 - Creating your database

The RDS instance is running.  The EC2 instance can see it.  Now we just need to create all of the tables in our mmdb database.  Since we've restricted access to our RDS instance to traffic coming from our EC2 instance, we'll need to run our database creation script from there.

- Note the .ebextensions folder in this repo.  This folder allows us to provide Elastic Beanstalk with [configuration scripts](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/customize-containers-ec2.html) to run for each EC2 instance started up within the environment.  We've added a script that installs postgres.  Without this script, you would need to install postgres on your EC2 instance before you could run psql commands.

1. #### Run the db creation script from EC2
    - You'll need the dns or 'endpoint' from your RDS instance.  You can find that under Services -> RDS
    - With psql, you can run any SQL commands stored in a file by invoking psql, pointing at the database, providing credentials, and adding the `-f [sqlfilename]` parameter
        - `psql -h [endpoint] mmdb -U mmadmin -f /var/app/current/scripts/db_init_prod.sql`

### Part 8 - Set up ECR (Elastic Container Registry)

We won't be using ECR immediately, but this will become useful when we incorporate Continuous Deployment from Travis-CI.  It's really easy to set up.

1. #### Set up ECR
    - Head over to ECR from the Services menu and `Create a repository`.  Let's name it `mm` for megamarkets.

    - Note the URI.  You'll come back for this in your CI/CD setup later.


### Part 9 - Environment Variables

We're nearly done!  Now all we have to do is give our application all of the information it needs to connect to our database.  Because this requires sensitive data (username and password), best practice is to supply these values through **environment variables**.  We can set these up with Elastic Beanstalk.

1. #### Set up your environment variables
    - Go to your megamarkets production environment and select Configuration -> Software
    - Add the following environment variables
        - NODE_ENV : production
        - RDS_HOSTNAME : [RDS 'endpoint']
        - RDS_DB_NAME : mmdb
        - RDS_USERNAME : mmadmin
        - RDS_PASSWORD : [your password]
        - RDS_PORT : 5432

### Part 10 - Verify that your application is working with the database

1. Open the Dashboard for your environment and follow the URL at the top to see your application running in the cloud.

1. Add some markets, cards, reload the page, **revel in the glory of your achievement!**

## Extensions

1. ### Set up AWS and EB CLI
    You can accomplish a lot of the tasks we've been doing with the AWS console from the command line using the AWS and EB CLI tools.  These tools also simplify things like getting your ssh connection to your EC2 instance.  

    1. **Install the AWS and EB CLI tools**
        - Follow the AWS CLI [installation instructions](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) for your OS
        - Follow the EB CLI [installion instructions](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install.html) for your OS
    1. **Configure**
        - Go to your development directory and run `aws configure` to set up your aws cli configuration
            - You'll need the information from your IAM credential csv file
        - Run `eb init` to set up your eb cli configuration
    1. **Login to EC2 using eb ssh**
        - Run `eb ssh` to connect to your current running instance

1. ### Set your environment up as 'high availibility' by adding auto scaling with a load balancer

    Currently, your EB environment is set up as 'single instance', so we only have one virtual machine to handle all of our network traffic.  We've already learned the value of dynamic horizontal scaling in a production environment.  So how do we set this up for our AWS EB application?

    **Note: Auto Scaling does not qualify as free tier.  This could result in AWS charges, so don't leave this up in your environment.**

    1. Go to your EB environment and select Configuration -> Capacity
    1. Change the Environment Type to 'Load Balanced'

        Take the default settings for now.  (The default triggers scale when the average outbound network traffic from each instance is higher than 6 MB or lower than 2 MB over a period of five minutes.)


1. ### Set up DNS with Route 53
    **Note: Domain names are not free with AWS.  If you do this your credit card will be charged for the domain name registration.**

    1. Go to Services -> Route 53
    1. Set up a new Domain Registration (again, this will incur a charge) and may from a few minutes up to a couple of days to process.  Even once it has been registered with AWS, it may take some time to propogate throughout the DNS system.  So it may take some time to finish this one.  
    1. During this process, AWS will automatically create a new 'Hosted Zone' with your new Domain
        - This will provide you with two records:
            - NS (name server)
            - SOA (Start of Authority)
        - You will need to add an 'A' record, this is what creates the mapping between the URL and the IP address of your host
            - Make this an alias record.  This way we can route it to our service rather than a specific IP address.
            - If you've created a load balancer, you'll point your A record at the load balancer.
            - If you have a single instance, you'll point your A record at the Elastic Beanstalk environment
    1. You can check DNS propogation through sites like [dnschecker.org](https://dnschecker.org)

1. Set up HTTPS access