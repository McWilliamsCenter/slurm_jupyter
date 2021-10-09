# slurm_jupyter

Below are my instructions for easy and fast implementation of jupyter notebooks on a SLURM cluster over SSH. These instructions are built for ready use on the Vera computing cluster (PSC-McWilliams Center), but can be generalized to any computing cluster that uses a recent version of SLURM.

There are two ways to run a jupyter notebook on a remote SLURM cluster: on a login node or on a compute node. The compute node instance gives you full access to the cluster's computational resources, but is slightly more difficult to set up than the login node method. 

Each method has its drawbacks: Heavy computation on a login node will clog up other users' access to the system, while the compute node method will waste resources when idle. You should use the login node method when doing simple, resource-light computation (e.g. data transfer/exploration, plot generation, etc.) and the compute node method for doing high memory or extended computation (e.g. model fitting, simulation, etc.). Please be conscientious of your use.

## Jupyter on a login node
### Setup
1. Install [jupyter and its dependencies](https://jupyter.org/install) in your home directory. I would recommend doing this within a [Conda environment](https://docs.conda.io/projects/conda/en/latest/user-guide/getting-started.html) for better module control. Vera has a pre-installed anaconda3 module environment that you can load with `module load anaconda3`.
2. Navigate to your account root directory `~` and generate a configuration file which dictates server settings. 
    ```console
    user@server:~$ jupyter notebook --generate-config
    ```
3. Generate a hashed password to secure your jupyter instances. The following command will prompt you to enter a password and will automatically write it to your configuration file.
    ```console
    user@server:~$ jupyter notebook password
    ```
4. Modify the configuration file located at `~/.jupyter/jupyter_notebook_config.py` and un-comment and change the following lines. You'll need to search through the config file to find each line.
    ```python
    c.NotebookApp.open_browser = False
    c.NotebookApp.port = 8888 # (You can set this to any four-digit integer)
    ```
    Choose a 4-digit port number other than `8888` to avoid overlapping with another user's jupyter instance

### Running
From your local machine, run 
```console
user@local:~$ ssh -L <port>:localhost:<port> -t <user>@<server> "jupyter notebook"
```

where  `<port>` is the port you set earlier, `<user>` is your cluster user id, and `<server>` is the address of the login server. The `-L` flag tells ssh to tunnel the `localhost:<port>` of the remote server to that of your local machine. The `-t` flag opens up the connection as an interactive session, allowing you to pass `SIGINT` (Ctrl-C) to end the jupyter notebook before killing the ssh connection. To open your jupyter notebook within a specific conda environment (e.g. `<env>`), replace the command in quotations with `source activate <env>; jupyter notebook`.


### Access
You can now access the jupyter server as if it was running on your own localhost. In your browser, navigate to ```http://localhost:<port>```.

### Exiting
You can end the jupyter instance and the `ssh` bridge by either clicking 'Quit' in the Jupyter Dashboard or passing `SIGINT` (Ctrl-C) to the running terminal.

### Notes
Here are some miscellaneous notes on running on a login node:
 * If you run into a "bash: jupyter: command not found" error, you have to replace the `"jupyter notebook"` command with the location of the jupyter binary in the server directories. You can find it using `which jupyter`.
 * If you're comfortable with leaving jupyter running indefinitely in the background on your server, remove the -t flag and add the -f flag. This forks the process to the background. Just know that, in order to shut down the server, you'll need to find the process ID and kill it manually. [Here's a stack overflow with how to do this.](https://stackoverflow.com/questions/9447226/how-to-close-this-ssh-tunnel)
 * You can wrap the long `ssh` command inside a simple bash script so you don't have to type it up every time. I've included my example in this repo as [vera_login.sh](vera_login.sh). This is run with:
    ```console
    user@local:~$ sh vera_login.sh
    ```
 * This procedure can be modified to run a [JupyterLab server](https://jupyterlab.readthedocs.io/en/stable/) instead of just Jupyter notebooks. To do so, simply replace `jupyter notebook` with `jupyter lab` in the above `ssh` command.

## Jupyter on a compute node
The below instructions will teach you how to submit a SLURM batch job to run an instance of jupyter on a compute node. Then, we will describe how to pipe signals from that compute node to your local machine to enable access through your local web  browser. The system configuration for vera is listed [here](https://github.com/pscedu/vera/blob/master/docs/index.md), including the available CPUs and memory of compute nodes.

This procedure is built off of this tutorial: http://docs.ycrc.yale.edu/clusters-at-yale/guides/jupyter/ , which describes a general procedure for remote jupyter access in a SLURM scheduler. Since that resource describes much of the what/how/why of the procedure, I'll just give you the important stuff.

### Setup
1. Follow __Setup__ steps from __Jupyter on a login node__
2. Copy [jupyter.job](jupyter.job) into your veera home directory `~`. This contains all the information necessary for the SLURM scheduler to run your jupyter instance.
3. Change the output-error directory to a desired (junk) folder (lines 6 and 7 in [jupyter.job](jupyter.job)).  Here, Jupyter will dump text files containing all the typical stuff that would otherwise be printed to terminal.
4. Change the desired `<port>` to the one chosen in the setup (line 11 in [jupyter.job](jupyter.job)).

### Running
1. From your home directory, run:
    ```console
    user@server:~$ sbatch jupyter.job
    ```
    This will submit your jupyter job to the cluster for execution. Assuming the cluster isn't too bogged down, your job should soon appear as RUNNING under your username.
    ```console
    user@server:~$ squeue
    ```
    Your job should be assigned a node, displayed in the `NODELIST` field (e.g. `compute-1-23`). The name of this node is necessary for the next step. I will refer to this as `<node>`.

2. In your local terminal, run the following command 
    ```console
    user@server:~$ ssh -N -L <port>:<node>:<port> <user>@<server>
    ```
    This forms a continuously running 'bridge' between your terminal and the compute node running your jupyter notebook. 
    
### Access
Finally, you should be able to access your jupyter server on a local web browser. In your browser, navigate to ```http://localhost:<port>```.

### Exiting
Lastly, to close everything, you have to both stop the job running on the cluster and also kill the bridge connecting you to the cluster. 
* To stop the jupyter job, you can either click 'Quit' in the Jupyter Dashboard or `scancel` the `JOBID` of your jupyter process.
* To close the ssh bridge, you can simply pass `SIGINT` (Ctrl-C) to the running bridge in your local terminal.

### Notes
* Feel free to play around with the requested resources in [jupyter.job](jupyter.job) (e.g. number of cpus, max runtime, etc.). 
* Like in __Jupyter on a login node__, you can also wrap the ssh command in a simple bash script. An example is presented in [vera_compute.sh](vera_compute.sh).

## Good luck!
Feel free to reach out to me at <mho1@andrew.cmu.edu> if you have any questions.
