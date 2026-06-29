# Running this repo with git on Terra

This is a one-time setup so the notebooks can be edited, run, and version-controlled
directly on a Terra cloud environment, with GitHub as the source of truth.

## Why clone outside a workspace-named directory

In "edit" mode, Terra automatically saves `.ipynb` files back to the workspace bucket
every few seconds, but **only for files in subdirectories named after a workspace**.
Files kept anywhere else on the persistent disk are left alone. So we clone the repo
into a non-workspace-named folder (e.g. `~/repos`), which keeps Terra's auto-sync and
git from interfering with each other. Work from the JupyterLab file browser in that
folder rather than the native "Notebooks" tab.

(Reference: Terra Support, "Jupyter Notebooks environment Part I/II" and "Cloud
environment storage".)

## One-time setup (in the Terra cloud-environment terminal)

Open JupyterLab on your cloud environment, then File > New > Terminal.

### 1. Identity and credentials

```bash
git config --global user.name  "Kenneth Westerman"
git config --global user.email "ken.e.westerman@gmail.com"
git config --global credential.helper store   # saves the token to ~/.git-credentials on the PD
```

Create a GitHub fine-grained personal access token (GitHub > Settings > Developer
settings > Fine-grained tokens) scoped to `westerman-lab/gxpa-lcms` with
**Contents: Read and write**. You will paste it as the password on the first push.

### 2. Clone into a non-workspace-named directory on the persistent disk

```bash
mkdir -p ~/repos && cd ~/repos
git clone https://github.com/westerman-lab/gxpa-lcms.git
cd gxpa-lcms
```

### 3. Activate output stripping

```bash
pip install nbstripout jupytext
nbstripout --install        # run inside ~/repos/gxpa-lcms
```

`.gitattributes` is already committed, so this just wires the strip filter into this
clone. After it, every commit stores notebooks with cell outputs removed; your working
copies keep their outputs.

### 4. (Optional) survive runtime re-creation

The clone, your token, and `~/.gitconfig` live on the persistent disk, so they survive
pausing and restarting the environment. If you ever delete the persistent disk, repeat
steps 1-3. To have `nbstripout`/`jupytext` reinstalled automatically on a fresh runtime,
add `pip install nbstripout jupytext` to the cloud environment's startup script
(Cloud Environment > Customize > Startup script).

## Day-to-day workflow

```bash
cd ~/repos/gxpa-lcms
git pull                      # get latest before working
# ... edit and run notebooks in JupyterLab from this folder ...
git add -A
git commit -m "describe the change"
git push
```

Pull the same way on your laptop to inspect. Notebook data still comes from the
workspace bucket via `gcloud storage` as before; that is independent of git.
