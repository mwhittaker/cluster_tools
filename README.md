# Cluster Tools
This repository contains a miscellany of command line tools that I find useful
when running code on a cluster of machines. For example, imagine you just
launched a bunch of EC2 instances. Here's what a workflow might look like.

```bash
$ ./ec2_ips.sh > hosts.txt                      # List EC2 IP addresses.
$ ./terminals.sh -u ec2-user -i key.pem         # SSH into all machines.
$ ./pssh.sh -u ec2-user -i key.pem provision.sh # Run script on all machines.
$ ./tmux_tail -w out out/*                      # Watch stdout of script.
$ ./tmux_tail -w err err/*                      # Watch stderr of script.
```
