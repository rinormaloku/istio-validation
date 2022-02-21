
if [[ -z "$ISTIO_VERSION" ]]; then
    echo "Must provide ISTIO_VERSION in environment" 1>&2
    exit 1
fi


echo "Tests start"

curl -L https://istio.io/downloadIstio | TARGET_ARCH=x86_64 sh -

# verify what istio reports
istio-${ISTIO_VERSION}/bin/istioctl verify-install
if [ $? -ne 0 ]
then
    echo "[ERROR] The command 'istioctl verify-install returned' errors"
    exit 1
fi
echo "✔ Successful response from 'istioctl verify-install'"

kubectl label namespace solo-validate-istio istio-injection=enabled
kubectl -n solo-validate-istio apply -f echo.yaml

## Wait until all pods are ready
kubectl -n solo-validate-istio wait po --for condition=Ready --timeout 200s --all
if [ $? -ne 0 ]
then
    echo "[ERROR] Took to long for the test pods to be run"
    exit 1
fi
echo "✔ Newly created pod was able to connect to istiod"

## Are all pods connected to the new istiod
TOTAL_CONN=$(istio-${ISTIO_VERSION}/bin/istioctl proxy-status | grep istio | wc -l)
NEW_CONN=$(istio-${ISTIO_VERSION}/bin/istioctl proxy-status | grep istio | grep $ISTIO_VERSION | wc -l )

if [ "${TOTAL_CONN}" -ne "${NEW_CONN}" ]; 
then 
    echo "[ERROR] NOT all pods are managed by the new istiod"
    exit 1
fi
echo "✔ All pods are managed by the new istiod instance"

## Verify kube injection occurred
POD_NAME=$(kubectl -n solo-validate-istio get pods -l app=echo-v1 -o jsonpath='{..metadata.name}')
istio-${ISTIO_VERSION}/bin/istioctl proxy-status "${POD_NAME}.solo-validate-istio"
if [ $? -ne 0 ]
then
    echo "[ERROR] The command 'istioctl proxy-status $POD_NAME' returned errors"
    exit 1
fi
echo "✔ The newly created pod has received its envoy configuration"


# Verify traffic can be routed according to the Gateway and Istio configuration
curl istio-ingressgateway.istio-system.svc.cluster.local -H "Host: echo.validate.istio"
if [ $? -ne 0 ]
then
    echo "[ERROR] Routing to the canary service failed"
    exit 1
fi
echo "✔ Traffic got routed to the new app through the ingress gateway"

echo "Clean up"
kubectl -n solo-validate-istio delete -f echo.yaml


echo "== All tests passed."
