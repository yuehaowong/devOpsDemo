# CI/CD with Travis-CI

## Summary

Travis-CI is a hosted, distributed continuous integration and deployment service used to build, test, and deploy software projects hosted at GitHub.

Once configured, Travis-CI will create web hooks to watch your Github repository for `pushes`,`pull requests` and `merges`.  When these web hooks are triggered, Travis-CI will spin up a virtual machine in which it will build your application and run `npm test`.  (Additionally, Travis-CI will follow any instructions you provide in a `.travis.yml` configuration file.)  The results of this test will be reported back to your Github repo.

In the case of `pushes` and `pull requests`, this **integration testing (CI)** is as far is it will go.  In the case of `merges`, Travis-CI will then shift into **deployment (CD)** mode.  Again, following the instructions set up in `.travis.yml`, it will deploy your code to the destination of your choice.  We'll be deploying to AWS.

## Challenges

### Part 1 - Sign up for Travis-CI

If you don't have a Travis account already, head over to the [Travis-CI](https://travis-ci.com/) website and sign up with your Github account.

1. Activate Github Apps Integration.  This will allow you access your Github repos from Travis-CI.  You'll be forwarded over to Github where ou can choose to provide access to all repos, or only specific ones.  For now just select unit-13-DevOps.

1. Back over in Travis-CI, open the `Settings` for unit-13-DevOps
    - Note that webhooks are set up for pushes and pull requests by default.  (It will always run on merges as well.)
    - Also note that there is a place here to set up environment variables.  In order for Travis-CI to have access to your AWS account, you'll need your IAM credentials.
        - Create an environment variable named 'AWS_ACCESS_KEY_ID' and set it as per your IAM credentials
        - Create an environment variable named 'AWS_SECRET_ACCESS_KEY' and set it as per your IAM credentials
     - Lastly, still in settings, click on 'Plan' and ensure you choose and confirm the Free plan. Without confirming the free plan your build won't start!

### Part 2 - Configure the repo for Travis

Travis-CI relies on `.travis.yml` in your repo for instructions on what it should do to run tests and deploy your code.  We'll also make use of two other files in this process:

- `Dockerrun.aws.json` - A configuration file for running docker on AWS
- `./scripts/deploy.sh` - A bash script that will execute all of the commands we need to deploy to AWS from within the virtual machine on Travis-CI.

As we create these files, we'll need two things from AWS:

- Your ECR repository URI.  You'll see it referenced here as [ECR URI].  Where you see it, replace it (including the brackets) with your ECR repository URI. You'll find that under Services -> ECR in AWS.
- The S3 bucket name that was created by Elastic Beanstalk.  You'll see it referenced here as [S3 BUCKET NAME].  Where you see it, replace it (including the brackets) with your S3 bucket name.  You'll find that under Services -> S3 in AWS.

1. #### Create `.travis.yml` in your repo's top level directory

    - Create a **services** key that contains an array.  The only element we'll add here is `docker`, so Travis will know that we'll need docker installed and running in the virtual machine that it spins up to test our code.
    
    - Create a **dist** key that contains a value `xenial`. This'll set our default build environment to Ubuntu Xenial.

    - Create a **script** key that contains an array of three elements.  Here we'll want to use `docker-compose` to build our testing container that we configured with our `docker-compose-test.yml` file.  We'll add a flag to tell Travis-CI to abort if we exit from the container.

        ```yaml
        docker-compose -f docker-compose-test.yml up --abort-on-container-exit
        ```
    - When we run our script, we dictate what version of python and pip (python's package management system) to use. The -v flags here will print all lines in the script before executing them, which helps identify which steps failed in the case of us hitting a snag in our deployment. The second and third elements in our **script** array will look like so:
    
        ```yaml
        python3 -VV
        pip -V
        ```

    That's all we need for Continuous Integration.  Now let's set up Continuous Deployment.

    - Create a **before_deploy** key that will use python's installer to install and configure the aws and eb command line interfaces inside of our virtual machine.  We'll also append the directory containing those executables to our PATH environment variable so the virtual machine will find them when we invoke the command.  This should contain an array of three elements:

        ```yaml
        # install the aws cli
        - python3 -m pip install --user awscli
        # install the elastic beanstalk cli
        - python3 -m pip install --user awsebcli
        # Append exe location to our PATH
        - export PATH=$PATH:$HOME/.local/bin
        ```
    - Create an **env** key, who's value will be another key **global**. The value of this key will be the following path:
    
        ```yaml
        - PATH=/opt/python/3.7.1/bin:$PATH
        ```

    - Create a **deploy** key.  Each element will instruct travis on where (and how) to deploy our code to AWS.

        There are different ways to accomplish this using S3 or Elastic Beanstalk.  Since we are doing a slightly more sophisticated deployment that includes Docker containers, we'll be using a bash script to do the heavy lifting.  This section will simply invoke the bash script.

    - Under **deploy**, create the following:

        - A **provider** key with a value of `script`.

        - A **skip_cleanup** key with a value of `true`.  This tells Travis-CI not to clear out of the files it built after it runs the test, as we may be using some of those assets.

        - An **on** key that has a key value pair of branch: master.  This tells Travis-CI that we only want to run this script on merges to the master branch.

        - A **script** key that tells Travis-CI to run our bash script from Travis-CI's build directory ($TRAVIS_CI_BUILD, which is supplied by Travis-CI):

            ```bash
            sh $TRAVIS_BUILD_DIR/scripts/deploy.sh
            ```

1. #### Create `Dockerrun.aws.json` in your repo's top level directory
    A [Dockerrun.aws.json](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/single-container-docker-configuration.html#single-container-docker-configuration.dockerrun) file describes how to deploy a remote Docker image as an Elastic Beanstalk application.  

    This json does the following:
     - Sets the Dockerrun version to 1
     - Instructs AWS to `pull` the image from the ECR repo
        - and overwrite any cached images
     - Route requests to the appropriate container port

    Note the `<VERSION>` tag in the image name.  This text will be replaced by the Travis-CI SHA when we Travis-CI runs our bash script.

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

1. #### Create `deploy.sh` in the `./scripts` directory

    This bash script moves all the files from our current build to the appropriate places in AWS to deploy our code.  Note that where you see `$TRAVIS_COMMIT` here, that is an environment variable supplied by Travis-CI that contains a SHA generated hash key that uniquely identifies this build.
    
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
    docker build -t [orgname]/mm .
    # tag the image with the Travis-CI SHA
    docker tag [orgname]/mm:latest [ECR URI]:$TRAVIS_COMMIT
    # Push built image to ECS
    docker push [ECR URI]:$TRAVIS_COMMIT
    # Use the linux sed command to replace the text '<VERSION>' in our Dockerrun file with the Travis-CI SHA key
    sed -i='' "s/<VERSION>/$TRAVIS_COMMIT/" Dockerrun.aws.json
    # Zip up our codebase, along with modified Dockerrun and our .ebextensions directory
    zip -r mm-prod-deploy.zip Dockerrun.aws.json .ebextensions
    # Upload zip file to s3 bucket
    aws s3 cp mm-prod-deploy.zip s3://$EB_BUCKET/mm-prod-deploy.zip
    # Create a new application version with new Dockerrun
    aws elasticbeanstalk create-application-version --application-name [your eb application name] --version-label $TRAVIS_COMMIT --source-bundle S3Bucket=$EB_BUCKET,S3Key=mm-prod-deploy.zip
    # Update environment to use new version number
    aws elasticbeanstalk update-environment --environment-name [your eb environment name] --version-label $TRAVIS_COMMIT
    ```

### Part 3 - Deploy!

It's all come down to this moment... we've containerized our application.  We've manually deployed it in the cloud.  We've set up CI/CD.  Now let's see it all work (fingers crossed!)

1. Create a new feature branch in your source repo.
1. Change some code -- update the color of your text in `styles.css`.
1. Add, commit, and push your feature branch up to Github.
1. In Github, create a Pull Request from your feature branch, to merge with `master`.
1. Open the Pull Request.  Notice the `checks` tab.  From here we can hop over to Travis-CI and see how our `push` and `pull request` tests are doing.  Just follow the `build` link.  (Best to right click and open it in a new tab, otherwise it will load over your github page).  Once they complete successfully, you should be able to commit the merge.
1. Once you `merge`, go back and watch that build on Travis. If that's successful, you should also open up your Elastic Beanstalk environment and watch it update.
1. As soon as it is done, go check out your **live, full stack, containerized React/Redux application built with full continuous integration and deployment!!!**
8. **CELEBRATE!!!  HIGH FIVE!! OMG!!**
