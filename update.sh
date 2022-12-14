#!/bin/bash

set -e pipefail

tempdir=$(mktemp -d)

### Helper
get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases" |                 # Get latest release from GitHub api
  jq --raw-output 'map(select(.tag_name |  test("^v.*"))) | map(select(.prerelease | not)) | map(select(.tag_name | test(".*beta.*")|not)) | map(select(.tag_name | test(".*alpha.*")|not)) | map(select(.tag_name | test(".*rc.*")|not)) | first | .tag_name'  # get the tag from tag_name
}

# helm repo add aad-pod-identity https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts
# helm repo add traefik https://traefik.github.io/charts
# helm repo add external-secrets https://charts.external-secrets.io
# helm repo add grafana https://grafana.github.io/helm-charts
# helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update

cd k8s/external-secrets-operator
rm -rf resources/render/
mkdir -p resources/render
helm template external-secrets \
   external-secrets/external-secrets \
    -n external-secrets \
    --set installCRDs=true | yq -s '"resources/render/" + .metadata.name + "-" + .kind + ".yml"' -
cd resources/render
kustomize create app --recursive --autodetect
cd ../../../..
echo "Upgraded external-secrets-operator"

# argoCDVersion=$(get_latest_release "argoproj/argo-cd")
# cd k8s/argocd
# rm -rf resources/render/
# mkdir -p resources/render
# kubectl create ns argocd -o yaml --dry-run=client > resources/render/ns.yaml
# curl -s https://raw.githubusercontent.com/argoproj/argo-cd/$argoCDVersion/manifests/install.yaml | yq -s '"resources/render/" + .metadata.name + "-" + .kind + ".yml"' -
# cd resources/render/
# kustomize create app --recursive --autodetect
# cd ../../../..
# echo "Upgraded argocd to $argoCDVersion"

# cd k8s/tekton
# rm -rf resources/render/
# mkdir -p resources/render
# curl -s https://storage.googleapis.com/tekton-releases/operator/latest/release.yaml | yq -s '"resources/render/" + .metadata.name + "-" + .kind + ".yml"' -
# curl -s https://raw.githubusercontent.com/tektoncd/operator/main/config/crs/kubernetes/config/all/operator_v1alpha1_config_cr.yaml | yq -s '"resources/render/" + .metadata.name + "-" + .kind + ".yml"' -
# rm .yml
# cd resources/render/
# kustomize create app --recursive --autodetect
# kustomize edit set namespace tekton-operator
# cd ../../../..
# echo "Upgraded tekton"

# certManagerVersion=$(get_latest_release "cert-manager/cert-manager")
# cd k8s/certmanager
# rm -rf resources/render/
# mkdir -p resources/render
# curl -sL https://github.com/cert-manager/cert-manager/releases/download/$certManagerVersion/cert-manager.yaml | yq -s '"resources/render/" + .metadata.name + "-" + .kind + ".yml"' -
# cd resources/render/
# kustomize create app --recursive --autodetect
# cd ../../../..
# echo "Upgraded certmanager to $certManagerVersion"

# cd k8s/traefik
# rm -rf resources/render/
# mkdir -p resources/render
# helm template traefik traefik/traefik \
#   -n traefik \
#   --set globalArguments= \
#   --set providers.kubernetesIngress.publishedService.enabled=true \
#   | yq -s '"resources/render/" + .metadata.name + "-" + .kind + ".yml"' -
# curl -sL https://raw.githubusercontent.com/traefik/traefik/master/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml  | yq -s '"resources/render/" + .metadata.name + "-" + .kind + ".yml"' -
# curl -sL https://raw.githubusercontent.com/traefik/traefik/master/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml | yq -s '"resources/render/" + .metadata.name + "-" + .kind + ".yml"' -
# cd resources/render/
# kustomize create app --recursive --autodetect
# cd ../../../..
# echo "Upgraded traefik"

cd k8s/external-dns/
externalDNSOperatorVersion=$(get_latest_release "kubernetes-sigs/external-dns")
git clone -q --depth=1 https://github.com/kubernetes-sigs/external-dns.git --branch $externalDNSOperatorVersion $tempdir/externaldns 2> /dev/null
rm -rf resources/render
mkdir -p resources/render
cp -R $tempdir/externaldns/kustomize/* resources/render
# Stupid workaround for properly doing this :facepalm:
kustomize edit set image k8s.gcr.io/external-dns/external-dns:$externalDNSOperatorVersion 
cd ../../
echo "Upgraded external-dns to $externalDNSOperatorVersion"

if [ -z $AWS_REGION ]; then
    echo "Could not find AWS_REGION. Stopping!"
    exit 1
fi

cd k8s/autoscaler/
rm -rf resources/render
mkdir -p resources/render
# curl -sL https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml | yq -s '"resources/render/" + .metadata.name + "-" + .kind + ".yml"' -
helm template autoscaler autoscaler/cluster-autoscaler \
  -n kube-system \
  --set autoDiscovery.clusterName=test \
  --set awsRegion=$AWS_REGION | yq -s '"resources/render/" + .metadata.name + "-" + .kind + ".yml"' -
cd resources/render/
kustomize create app --recursive --autodetect
cd ../../../..
echo "Upgraded autoscaler"



# Cleanup
rm -rf $tempdir