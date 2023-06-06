# url-shortify-eks

AWS EKS cluster for [url-shortify](https://github.com/url-shortify).

## Usage

```shell
# prepare environment
cd ./live

# clone and update global.yaml
# one can use `python3 -c "import os, binascii; print(binascii.hexlify(os.urandom(4)).decode())"` to generate a project ID
cp sample.global.yaml global.yaml

# create supporting resources
cd ./live/base
terragrunt apply

# update Kubectl configuration
(EKS_CLUSTER_NAME=$(terragrunt output -json eks_cluster_name | jq -r) && aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --alias $EKS_CLUSTER_NAME)

# enable EKS addons
cd ./live/addons
terragrunt apply

# use port forwarding to access ArgoCD UI, the initial password for admin user is in AWS Secrets Manager
kubectl --namespace argocd port-forward svc/argo-cd-argocd-server -n argocd 8080:443

# deploy EKS workloads
cd ./live/workloads
terragrunt apply

# run database migrations
kubectl exec --namespace url-shortify deployments/url-shortify -- npm run migrations
```

## Development

```shell
pre-commit install --hook-type pre-commit --hook-type commit-msg
```
