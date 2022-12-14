# Kubeadm-init-script

## What is it?
This is a collection of bash script to create k8s cluster on numbers of physical machine.

## System Information
Master node
```
Linux 
aisf-orchestrator 
5.4.0-132-generic 
#148-Ubuntu SMP Mon Oct 17 16:02:06 UTC 2022 x86_64 x86_64 x86_64 GNU/Linux
```
Worker node
```
Linux 
aisf-fog 
5.4.0-131-generic 
#147-Ubuntu SMP Fri Oct 14 17:07:22 UTC 2022 x86_64 x86_64 x86_64 GNU/Linux
```
```
Linux 
aisf-edge 
5.4.0-124-generic 
#140-Ubuntu SMP Thu Aug 4 02:23:37 UTC 2022 x86_64 x86_64 x86_64 GNU/Linux
```
```
Linux 
aisf-cloud 
5.4.0-126-generic 
#142-Ubuntu SMP Fri Aug 26 12:12:57 UTC 2022 x86_64 x86_64 x86_64 GNU/Linux
```

## How to run it?
> ⚠️ **The following step should be run in root mode, and be careful**

Master node
1. Run `bash install.sh` to install k8s utilities
2. Run `bash master.sh` to create cluster
3. Run `cat kubeadm-init.log` to see the token, hash token and ip information (this will be used later on).

Worker node
1. Run `bash install.sh` to install k8s utilities
2. Create `token.sh` with the following content
   ```
   export CONTROL_PLANE_IP=<according to kubeadm-init.log>
   export TOKEN=<according to kubeadm-init.log>
   export HASH_TOKEN=<according to kubeadm-init.log>
   ```
3. Run `source token.sh` to load the environment variable
4. Run `bash worker.sh` to join the cluster

## Command detail explanation
Check blogs:
- [Blog 1](https://medium.com/@aaaa102234/lets-build-k8s-hosting-k8s-on-your-local-machines-1-d2c33b992884)
- [Blog 2](https://medium.com/@aaaa102234/lets-build-k8s-hosting-k8s-on-your-local-machines-2-bf8c2dc00b96)
- [Blog 3](https://medium.com/@aaaa102234/lets-build-k8s-hosting-k8s-on-your-local-machines-3-4d02b0d90847)