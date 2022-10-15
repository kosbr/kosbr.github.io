---
layout: post
title:  "The cheapest kubernetes cluster for personal usage (not production)"
date:   2022-10-15 00:00:00 +0700
categories:
tags: Kubernetes Microservices
---

Everybody who worked with kubernetes knows how powerful and convenient it is. If you are an engineer, and 
you need a kubernetes cluster for your personal purposes you may find it quite expensive. However you
can save your money if you configure it by yourself.
![Kubernetes](/images/articles/cheapest-k8s/logo.jpg)

### Preconditions

Imagine you need a personal kubernetes cluster to host personal applications or just to learn kubernetes. 
Here are options you have:

- minikube
- cloud provider (like AWS)
- self-hosted machines united into a kubernetes cluster 
- several VMs manually connected to cluster

Let's say we are talking about a cluster of 3 nodes. Here is the comparison of different ways to implement it:

----

|      Option      | Initial price |  Per year price  |              Pros               |            Cons             |
|:----------------:|:-------------:|:----------------:|:-------------------------------:|:---------------------------:|
|     Minikube     |      $0       |        $0        |         Easy to set up          | A toy, not scalable at all  |
|  Cloud provider  |      $0       |      ~$1000      |         Easy to set up          |              -              |
|   Self-hosted    |    > $1000    |        $0        |          Full control.          | Hardware, noise. Difficult. |
|   several VMs    |      $0       |      ~$500       |      Almost full control.       |         Difficult.          |

----

I wanted to save money and get some experience in kubernetes cluster administration. Actually my dream is to have own cluster with
raspberries, but they costed too much, so I decided to rent 3 virtual machines and unite them into a cluster.

**Of course, this is not for production!!!** 

### Renting VMs

The first step is to find provider who gives you 3 cheap VMs. Don't use AWS or similar providers, better find some small
provider you'd never trust work production data to :) . I took 3 VMs:

- master 2GB 2Core 10GB HDD
- worker1 2GB 2Core 10GB HDD
- worker2 2GB 2Core 10GB HDD

Better to have at least 2GB RAM per each node because otherwise kubernetes will display a message that it is highly
recommended increasing memory, and I believe it. 

### Set up machines

If the provider allows it, create a private subnet. So VMs will be available to call each other using private IPs.

Most of the following actions must be performed on each machine. Google helps if something goes wrong.

#### Step1: set hostnames on each machine

```hostnamectl set-hostname k8s-master1.kosbr.local```

```hostnamectl set-hostname k8s-worker1.kosbr.local```

```hostnamectl set-hostname k8s-worker2.kosbr.local```

Then it is needed to edit `/etc/hosts` on each machine to provide availability by new host names. 
Use IPs of each machine.

```
10.12.0.1     k8s-master1.kosbr.local k8s-master1
10.12.0.2     k8s-worker1.kosbr.local k8s-worker1
10.12.0.3     k8s-worker2.kosbr.local k8s-worker2
```

#### Step2: Install needed soft

```
apt update && apt upgrade
apt install curl apt-transport-https git iptables-persistent
```

#### Step3: Disable swap

```
swapoff -a
```

and comment this line in `/etc/fstab`

```
#/swap.img      none    swap    sw      0       0
```

#### Step4: Load needed modules

Create file `/etc/modules-load.d/k8s.conf` with content
```
br_netfilter
overlay
```
and then launch 
```
modprobe br_netfilter
modprobe overlay
```

#### Step5: A bit more settings

create file `/etc/sysctl.d/k8s.conf` and write this:

```
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
```

and apply changes

`sysctl --system`

#### Step6: install docker

Launch 
```
apt install docker docker.io
systemctl enable docker
```

and create file `/etc/docker/daemon.json` and write

```
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
```

then

```
systemctl restart docker
```

and kubernetes

```
systemctl restart docker
```

#### Step7: install kubernetes

```
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
```

Create file `/etc/apt/sources.list.d/kubernetes.list` and write this line:

`deb https://apt.kubernetes.io/ kubernetes-xenial main`

Then launch:

```
apt update
apt install kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
```

#### Step8: Init cluster

Init master node:
```
kubeadm init --pod-network-cidr=10.244.0.0/16
```

It produces the command to be launched on worker nodes to join the cluster. 
Launch it on each worker.

Then cluster is ready. You can manage to set up config to be available
to use kubectl to manage the cluster.

### Add volumes (not best practise!!!)

Ideally applications in kubernetes cluster must have no volumes. However, this is home cluster
and all rules are not so strict, moreover you might want to install some applications with volume to the cluster.

So the goal is to be able to install applications with some state which is written to file, and it should be ok if 
this app moves to another node = state files must be available in each node.

There are many solutions of this problem, let me provide the easiest one for home cluster. The idea is split task into two 
solutions:

1. Have a shared folder between nodes using nfs-kernel-server
2. Set up kubernetes to have host volume on this shared volume

nfs-kernel-server will provide that content of the folder is the same but with delay. **So this solution is not ok for 
concurrent access.**

#### Step1: Install nfs-kernel

```
apt-get install nfs-kernel-server nfs-common
```

Create shared folder on each node:

```
mkdir /k8data
```

On master node edit file `/etc/exports` and write (considering the IPs you want to have access to the folder)
```
/k8data 10.12.0.1/255.255.0.0(rw,insecure,nohide,all_squash,anonuid=1000,anongid=1000,no_subtree_check)
```
then restart the app
```
/etc/init.d/nfs-kernel-server restart
```

On each worker node edit file `/etc/fstab` and add line (considering your master's IP)
```
10.12.0.39:/k8data /k8data nfs user,rw 0 0
```

After that, the folder `/k8-data` wille be shared between nodes in both directions. Check it.
Reboot nodes if it doesn't work.

#### Step2: Using volumes in kubernetes config

Actually I used for grafana&prometheus in my kubernetes cluster. Let me share a piece of my helm config for grafana 
(it needs volume for storing settings)

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
        - name: grafana
          image: grafana/grafana-oss
          ports:
            - containerPort: 3000
          volumeMounts:
            - name: grafana-data
              mountPath: /var/lib/grafana
      volumes:
        - name: grafana-data
          persistentVolumeClaim:
            claimName: grafana-host-mapped-pvc
```
and volume configs
```
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: grafana-pv
spec:
  capacity:
    storage: 300Mi
  accessModes:
    - ReadWriteOnce
  storageClassName: grafana
  hostPath:
    path: /k8data/grafana
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: grafana-host-mapped-pvc
spec:
  storageClassName: grafana
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 300Mi
```

That's it. Test it by redeploying instance to another node. It should be invisible for end user. 

### Conclusion

- It is possible to have own kubernetes cluster for price less than $40/month
- It can be used for learning&home purposes, but not for production
- This is raw cluster. For example, you must install ingress to use it. It can be not simple.
- **Only professionals should prepare kubernetes infrastructure for production projects. Or just use ready cloud solutions.**


Read my another article [article](/2022/10/15/helm-best-practises.html) about bests practises of deploying to kubernetes.


