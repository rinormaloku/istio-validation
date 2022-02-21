## Building the container
docker build -t rinormaloku/solo-validate-istio . 
docker push rinormaloku/solo-validate-istio:latest

## Creating the cluster
kind create cluster --name validate-istio 
docker pull rinormaloku/solo-validate-istio:latest
kind load docker-image --name="validate-istio" rinormaloku/solo-validate-istio

# Installing Istio 1.10.5
i1105 install --set profile=demo -y

## Installing validation permissions
kubectl apply -f rbac.yaml

## Run the validation job for istio 1-10-5
kubectl -n solo-validate-istio apply -f solo-debug-admin-1-10-5.yaml

## Verify result
kubectl -n solo-validate-istio wait --for=condition=complete --timeout=-1s job/solo-validate-istio-job 

## Cleanup validation
kubectl delete ns solo-validate-istio

# Upgrade to Istio 1.11.4
i1114 install --set profile=demo -y

## Installing validation permissions
kubectl apply -f rbac.yaml 

# Run the validation job for 1-11-4
kubectl apply -f solo-debug-admin-1-11-4.yaml

## Verify results
kubectl -n solo-validate-istio wait --for=condition=complete --timeout=-1s job/solo-validate-istio-job 

## Cleanup validation
kubectl delete ns solo-validate-istio
