# Ansible intro

[Ansible](https://www.ansible.com/) is an **open-source automation tool** for configuration management, application deployment, and orchestration. It uses **YAML playbooks** to describe the desired state of systems and communicates over **SSH**. It is agentless, which means there is no need to install anything on the target machines.

## Why Ansible?

- **Agentless**: No need to install extra software on managed machines;
- **Idempotent**: Tasks can be run repeatedly without unwanted side effects;
- **Human-readable**: Playbooks use YAML, easy to write and review;
- **Scalable**: Manage a handful of servers or thousands with the same commands.

Some things we have inside a Dockerfile for instance are specific for docker.
However, if you put the instructions in an ansible playbook, those can be
executed outside docker, making this solution more reusable by different
environments. If you are working with docker you could have also a playbook to
have instructions that are targetted to the host and to the docker container.

## Alternatives

If Ansible is not available, one could use:
- **Shell scripts** with `ssh` and `scp` for manual automation;
- **Configuration management tools** like **Puppet** or  **Chef** (these often require agents on target mmachines);
- **Cloud-native tools** such as AWS CloudFormation, Terraform, or Azure Resource Manager (for infrastructure provisioning).



## Major components

- **Inventory:** A list of machines (hosts) Ansible manages.
- **Modules:** Small, reusable programs that perform one action (install a package, copy a file, manage a service, etc.).
- **Tasks:** Single steps executed on target hosts; each task calls a module with parameters.
- **Plays:** A mapping that says “run these tasks on these hosts”.
- **Playbooks:** YAML files containing one or more plays. They describe how and which order, at what time and where, and what modules should be executed. It orchestrates the modules' execution.
- **Handlers:** Special tasks executed only when notified by other tasks (useful for actions like restarting a service after config change).
- **Roles:** Redistributable units of organization that allow users to share automation code easier.
- **Variables:** Key–value pairs to parametrize playbooks, templates, and roles.


## Simple test VM

Simple example, for instance, once you provision a cloud VM (e.g. almalinux vm).

```
sudo dnf -y install epel-release
sudo dnf -y install ansible
ansible --version
```


Create inventory file (`inventory`):

```
[local]
localhost ansible_connection=local
```


Create playbook file (`simple.yml`). This is a playbook with a single play and
three tasks.

```yaml title="Simple"
--8<-- "docs/misc/ansible/simple.yml"
```




Run the line below and the file in `/tmp/` should be created.

```
ansible-playbook -i inventory simple.yml
```


If one wants to use multiple machines, replace 'hosts: local' with 'hosts: all'
in the `simple.yml` and update the inventory with the list of ip addresses. Also
remove `connection: local`.


## Further notes


List available modules:

```
ansible-doc -l
```

More details on a particular module (e.g. `copy`):

```
ansible-doc copy
```


Can also find modules docs online at: [WEBSITE](https://docs.ansible.com/ansible/latest/collections/index_module.html)

Test connections:

```
ansible all -m ping -i inventory
```

Show inventory:

```
ansible-inventory --list -y -i inventory
```

Append extra verbose mode using `-vvv`:

```
ansible-playbook -i inventory simple.yml -vvv
```
