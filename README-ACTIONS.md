# CI/CD with GitHub Actions

## Summary

GitHub Actions is a GitHub's built-in continuous integration and deployment platform. It automates the process of building, testing, and deploying software projects hosted on GitHub.

Actions for a given project are made up of **workflows** - configuration files describing one or more **jobs** that should run in response to a specific **event**, such as a pull request or merge. When a workflow is triggered by one of these events to run, GitHub will spin up a virtual machine (called a "runner") to run each specified job.

You can find further information about how Actions work in [GitHub's official docs](https://docs.github.com/en/actions). Keep the docs handy and open - they will be a helpful reference from this point on!

In this part of the challenge, we'll be setting up workflows for continuous integration and deployment on our MegaMarkets app. The end result will be as follows:
- Whenever a pull request is made to the `main` branch, GitHub will run our unit tests (`/client/test/reducer-test.js`) for continuous integration.
- When any changes are pushed or merged into the `main` branch, GitHub will first run our tests, and if they pass, deploy the updated code to AWS.


## Challenges

### Setup

#### Enable Actions

To start off, you'll need to ensure that Actions are enabled on your GitHub repo. To do this:

- Navigate to the _"Settings"_ tab
- Expand the _"Actions"_ menu
- Make sure the _"Allow actions and reusable workflows"_ option is selected
- Click _"Save"_

#### .github directory

Actions workflows must always be stored in a `.github` directory at the top level of your repository.

- Create this directory, and add a subfolder called `workflows`. By default, GitHub will look here to find any workflows that it should run.

Each workflow will be stored as an individual YAML file under the `.github/workflows` directory. We'll first be creating our workflow for integration testing, so let's move on!


### Part 1 - Integration Testing

Our integration testing workflow will run our unit tests on any pull requests made to the `main` branch, so that we can ensure the new code passes before merging it in. We'll be instructing GitHub to use our public Docker images to spin up a container and run the tests.

- In the `workflows` folder, create a file `build-tests.yml`. This file will define our workflow for testing our build.

- In the YAML file, you'll first want to define a **name** key. This will be what GitHub displays on its UI when the workflow is running. Let's set it to `build-tests`.

- The **on** dictionary will define which event(s) should trigger our workflow to run. Each applicable event may be stored as a separate dictionary within it. In this case, we'll want to create a **pull_request** dictionary that contains an array of **branches** that we want our workflow to apply to. In this case, we'll just be using the main branch.

- The **jobs** dictionary contains a key for every job that is part of a workflow. As above, each job will be stored as another dictionary. Our workflow, for now, will just have one job - let's call it **unit-testing**. (If we also had integration or end-to-end tests set up, we could add separate jobs for these as well.)

- Our unit-testing job should include the following keys:
    - **runs-on** will determine which type of machine the job will run on. GitHub offers various MacOS, Windows, and Linux runners - here, we'll be using the latest version of Ubuntu. Set this key to `ubuntu-latest`.
    - **steps** defines the sequence of tasks that will make up our job. It will be an array of key-value pairs.
        - Our first step will make use of a pre-published, reusable Actions workflow called [Checkout](https://github.com/actions/checkout), which checks out our latest commit to the runner's default working directory. This allows our workflow to access it. To use Checkout, we'll include a key called **uses** and set it to `actions/checkout@v3`.
        - Our next step will actually run our tests. It will consist of a **run** key, whose value is the script we want to run. We'll be using `docker-compose` to build our testing container that we configured with our `docker-compose-test.yml` file.  We'll add a flag to tell GitHub to abort if we exit from the container. 

    ```yaml
    docker-compose -f docker-compose-test.yml up --abort-on-container-exit
    ```

Now, it's time to test your workflow!

1. Create a new feature branch in your source repo.
2. Change some code -- update the color of your text in `styles.css`.
3. Add, commit, and push your feature branch up to Github.
4. In Github, create a Pull Request from your feature branch, to merge with your `main` branch.
    - **Note:** When creating a pull request from your fork, you will generally be redirected to the Pull Request page in the CodesmithLLC base repository. At the time of writing, the GitHub site has a glitch affecting certain repos with over 200 forks, which may prevent you from being able to search for your own fork in the dropdown menu to set it as your base. If this is the case, you will need to change `CodesmithLLC` in the URL to your own GitHub handle to redirect the PR back to your fork.
5. You'll be able to view your Actions workflows from either the "Actions" tab on the main repo, or the "Checks" tab on the Pull Request page. If you've set everything up correctly, you should see your `build-tests` workflow running, and the tests should pass. If your workflow fails, you'll want to expand it to look at the error messages, and debug from there. If it passes, you're ready to move on to the next section and set up continuous deployment!


### Part 2 - Continuous Integration & Deployment

We're going to create a new workflow for deployment. This one will run two jobs: our tests, and then a script to deploy our application to ElasticBeanstalk.

#### Step 1 - Add secrets to our repository

This script will make use of the AWS access keys we previously created, so first things first, we'll need to configure GitHub to be able to use them. 

- In your repository, navigate to the 'Settings' tab. On the lefthand side menu, under 'Security', you'll see an option for 'Secrets and Variables`. Expand this, and click on 'Actions'.

- Click on the 'New repository secret' button to create a secret. Set the name to `AWS_ACCESS_KEY_ID`, and the secret to the value of the *access key* you created in AWS.

- Now, create another secret named `AWS_SECRET_ACCESS_KEY`, and set it to the value of the access key's corresponding *secret key*. (Remember, you cannot find this secret in AWS if you didn't save it - in that case you'll need to create a new acceess/secret key pair.)

And that's it! Our access keys are now saved in our repository as secrets. Now let's move on to setting up our workflow.

#### Step 2 - Configure the deployment workflow

- In the `.github/workflows` directory, create a new file called `deploy.yml`.

- Give this workflow a name of `deploy`, and set it to be triggered by a `push` event on the `main` branch.

- Set up the first job to run our unit tests, the same way you did for the previous workflow.

- Directly below, add a second job called `deploy`. 
    
- GitHub Actions runs jobs *concurrently* by default, but that's not what we want here - we'll want to wait until our `unit-testing` job finishes successfully before running this one (i.e., we don't deploy to AWS unless our tests have passed!!!). To configure this, add a **needs** key to the second job. This key may be set to either a single value or an array, specifying the name of any job(s) that must complete before the current one runs.

- As with our previous job, set this one to run on `ubuntu-latest`.

- Next, we'll add the steps to compete our job. This one will have a few more:

    - Once again, we'll be using `actions/checkout@v3` to make our repo available to the workflow.

    - We'll be using a second reusable workflow, [setup-python](https://github.com/actions/setup-python), to install python for the AWS EB CLI to use. Our second step will be a dictionary with two keys: 
        - **uses**, set to `actions/setup-python@v4`
        - **with**, set to another dictionary with a key of **version** and a value of `'3.x'`. This will tell the workflow to use the latest Python 3 release.

    - The AWS EB CLI requires a specific preinstalled version of pip (phython's package management system), so we'll want to make sure this is up to date. To do this, add another step to **run** the script `python3 -m pip install --upgrade pip`.

    - Next, we'll use python's installer to install and configure the aws and eb command line interfaces inside of our virtual machine. Add two more steps to run the following scripts:
        - `python3 -m pip install --user awscli`
        - `python3 -m pip install --user awsebcli`

    - Our final step will be to run a bash script for deployment - which we haven't created quite yet, but will be in a later step. For now, add another **run** key with a value of `sh ./scripts/deploy.sh`. 

- Our bash script will make use of a few additional pieces - it will need a reference to our AWS access/secret keys, as well the head commit of our main branch. We'll be storing these as environment variables so the script can access them. To do this, add an **env** key to the deploy job. It will be a dictionary consisting of the following key-value pairs:
    - A key **AWS_ACCESS_KEY_ID**, set to `${{ secrets.AWS_ACCESS_KEY_ID }}`. This will reference the AWS_ACCESS_KEY_ID secret we saved earlier.
    - Do the same for the **AWS_SECRET_ACCESS_KEY**.
    - A key, **GITHUB_SHA**, set to `${{ github.sha }}`. This references the hash of our main branch's head commit.
    
We're getting close! We'll just need a couple more files before we're ready to go.

#### Step 3 - Create `Dockerrun.aws.json` 

- In your repo's top level directory, add a file called `Dockerrun.aws.json`.

    A [Dockerrun.aws.json](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/single-container-docker-configuration.html#single-container-docker-configuration.dockerrun) file describes how to deploy a remote Docker image as an Elastic Beanstalk application.  

    This json does the following:
     - Sets the Dockerrun version to 1
     - Instructs AWS to `pull` the image from the ECR repo
        - and overwrite any cached images
     - Route requests to the appropriate container port

    Note the `<VERSION>` tag in the image name.  This text will be replaced by the GitHub SHA when GitHub runs our bash script.

    Make sure to update the [ECR URI] with your Elastic Container Registry URI.

   ```json
    {
    "AWSEBDockerrunVersion": "1",
        "Image": {
            "Name": "[ECR URI]:<VERSION>",
            "Update": "true"
        },
        "Ports": [{
            "ContainerPort": "3000"
        }]
    }
    ```

#### Create bash script for deployment

Our final step will be to create the bash script that our workflow will run to deploy our build to ElasticBeanstalk.

- Create a file `deploy.sh` in the `./scripts` directory (as referenced previously in the job's configuration).

This bash script moves all the files from our current build to the appropriate places in AWS to deploy our code.  Note that where you see `$GITHUB_SHA` here, that is an environment variable supplied by GitHub that contains a SHA generated hash key that uniquely identifies this build.
    
*Remember to swap out any values below in [ ] with appropriate values for your application (e.g. S3 BUCKET NAME, YOUR AWS REGION)*

    ```bash
    echo "Processing deploy.sh"
    # Set EB BUCKET as env variable
    EB_BUCKET=[S3 BUCKET NAME]
    # Set the default region for aws cli
    aws configure set default.region [YOUR AWS REGION]
    # Log in to ECR
    eval $(aws ecr get-login --no-include-email --region [YOUR AWS REGION])
    # Build docker image based on our production Dockerfile
    docker build -t [accountname]/mm .
    # tag the image with the GitHub SHA
    docker tag [accountname]/mm:latest [ECR URI]:$GITHUB_SHA
    # Push built image to ECS
    docker push [ECR URI]:$GITHUB_SHA
    # Use the linux sed command to replace the text '<VERSION>' in our Dockerrun file with the GitHub SHA key
    sed -i='' "s/<VERSION>/$GITHUB_SHA/" Dockerrun.aws.json
    # Zip up our codebase, along with modified Dockerrun and our .ebextensions directory
    zip -r mm-prod-deploy.zip Dockerrun.aws.json .ebextensions
    # Upload zip file to s3 bucket
    aws s3 cp mm-prod-deploy.zip s3://$EB_BUCKET/mm-prod-deploy.zip
    # Create a new application version with new Dockerrun
    aws elasticbeanstalk create-application-version --application-name [your eb application name] --version-label $GITHUB_SHA --source-bundle S3Bucket=$EB_BUCKET,S3Key=mm-prod-deploy.zip
    # Update environment to use new version number
    aws elasticbeanstalk update-environment --environment-name [your eb environment name] --version-label $GITHUB_SHA
    ```

### Part 3 - Deploy!

It's all come down to this moment... we've containerized our application.  We've manually deployed it in the cloud.  We've set up CI/CD.  Now let's see it all work (fingers crossed!)

1. Create another feature branch, make some changes, and make a pull request to your `main` branch! (Alternatively, you can update your `main` branch locally and push up the changes - either approach should trigger your deployment workflow to run.)
6. Once you `merge`, go back and watch your Actions workflow in progress. If the unit-testing job passes, GitHub will move on to run the deploy job. If that's successful, you should also open up your Elastic Beanstalk environment and watch it update.
7. As soon as it is done, go check out your **live, full stack, containerized React/Redux application built with full continuous integration and deployment!!!**
8. **CELEBRATE!!! HIGH FIVE!! OMG!!**
