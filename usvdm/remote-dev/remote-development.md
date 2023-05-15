# Remote development on (Azure) cloud with Visual Studio Code

## A. Create a VM on the cloud

Creating a VM on Azure (or any cloud) can simply be done by:
- Go to [Azure Portal](portal.azure.com)
- Choode `Virtual machines`
- Click on first item on the menu: `+Create`
- Choose `Azure virtual machine`
- On the `Create a virtual machine` most default options are fine, however you might need to choose
    + Give it a name, for example `test-vm`.
    + Region: `(Canada) Canada central`.
    + Image: `Ubuntu Server 20.04 LTS - x64 Gen2 (free services eligible)`.
    + Authentication type: `SSH public key` (generate one on your local machine).
    + Username: <your username>.
    + SSH public key source: `Use existing public key` (the one you have generated).
    + Key pair name: <paste the content of ~/.ssh/id_rsa.pub>.
    + On `Networking` tab, chose a virtual network (probably already created), then create a `Public IP`.
    + The rest can be defaults.
    + Create the VM.
- Now check the Public IP Addess of the VM, note it down.
- On your machine, edit `~/.ssh/config` by adding

```bash
Host test-vm
	HostName 20.116.243.170
```

- Connect to the VM from your local terminal:

```bash
ssh test-vm
```

## B. Remote devlopment environment

### B.1 Setup remote access for `vscode`

- Install `vscode` on your local machine
- Install `Remote - SSH` extension.
- Press `Shift-Ctrl-P` to prompt extension execution, then type `Remote-SSH`, select `Remote-SSH: Connect to Host`, click on `test-vm` (read from `~/.ssh/config`), then wait for `vscode` to be remotely deployed.

### B.2 Get `gh` ready

- [Install `gh`](https://github.com/cli/cli/blob/trunk/docs/install_linux.md)

```bash
type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y
```

- On [Github tokens](https://github.com/settings/tokens) Generate new token (classic). The minimum required scopes are 'repo', 'read:org', 'workflow'. Copy and save the token.

- On the terminal: 
```bash
gh auth login
> Github.com
> HTTPS
> Authenticate Git with your GitHub credentials
> Paste your authentication token
```

- Now lets clone an example repository

```bash
gh repo clone gphin/gphin-data-pipeline
cd gphin-data-pipeline
git checkout --track origin/2-setup-a-kafka-cluster-in-docker-for-local-development
```

- Setup local user info

```bash
git config --global user.email nghia.doan@phac-aspc.gc.ca
git config --global user.name "Nghia Doan"
```

- Now you can use `vscode` to open the remote folder `gphin-data-pipeline`, open a text file, add an empty line at the end, then save it and then

```bash
git status
git commit -m ‘Add empty line’
git push
```

Now you have a remote development environment on the cloud.