# Setting up the Windows Subsystem for Linux for Unit-13-DevOps

## If you are on Windows but not already using WSL

- Follow this [link to our precourse material](https://github.com/CodesmithLLC/precourse-part-1/blob/master/windows-os.md). You will find instructions on how to properly setup WSL, VS Code, and Node.js on your machine.

## Setting up Docker Desktop on Windows

_Note:_ The following instructions are adapted from the [official Docker documentation](https://docs.docker.com/docker-for-windows/wsl/#install).

1. Follow the usual installation instructions to install Docker Desktop. If you are running a supported system, Docker Desktop prompts you to enable WSL 2 during installation. Read the information displayed on the screen and enable WSL 2 to continue.

2. Start Docker Desktop from the Windows Start menu.

3. From the Docker menu, select **Settings** > **General**.

   ![use-wsl2-based-engine](https://github.com/CodesmithLLC/unit-13-devops/blob/master/docs/assets/images/wsl2-enable.png)

4. Select the **Use WSL 2 based engine** check box.

   - If you have installed Docker Desktop on a system that supports WSL 2, this option will be enabled by default.

5. Click **Apply & Restart**.

6. When Docker Desktop restarts, go to **Settings** > **Resources** > **WSL Integration**. The Docker-WSL integration will be enabled on your default WSL distribution.

   ![wsl2-choose-distro](https://github.com/CodesmithLLC/unit-13-devops/blob/master/docs/assets/images/wsl2-choose-distro.png)

7. Click **Apply & Restart**.

## You will need to reclone this repo!

Before you continue on with this unit, you will need to reclone this repo into WSL. WSL manages it's own file system separately and has signigicant fundamental differences from Windows. Docker relies on a Linux environment and makes certain assumptions wherever it is run.

In a **WSL terminal**, run the following command:

`cd ~`

This changes your current directory in the terminal to your Ubuntu home directory. From there, `git clone` your forked repo and continue with the unit. **You must do all of the unit in the WSL/Ubuntu file system.**

## How to see your files in File Explorer

With WSL, there is one extra step if you ever want to see your files in a GUI File Explorer instead of just the command line. The following two-step process is what you would do in order to open a File Explorer window that shows your current directory of files.

1. Use the `cd` command to navigate to whichever directory you want to open with File Explorer.

2. Once you are in the directory you wish to be in, run the following command:

   `explorer.exe .`

   Take note of the extra `.` at the end of the command. The `.` represents the current directory. So when we run the `explorer.exe` command, we are simply passing in the path to the folder we want it to open. Once it is open, you can do everything else you normally would as if you opened a normal folder on your desktop.
