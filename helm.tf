provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "argocd" {

  depends_on = [null_resource.kubeconfig, helm_release.nginx-ingress]

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  set = [
    {
      name  = "server.ingress.enabled"
      value = true
    },
    {
      name  = "server.ingress.ingressClassName"
      value = "nginx"
    },
    {
      name  = "global.domain"
      value = "argocd-${var.env}.rdevopsb87.online"
    },
    {
      name  = "configs.params.server\\.insecure"
      value = true
    }
  ]
}

resource "helm_release" "prometheus-stack" {

  depends_on = [null_resource.kubeconfig,helm_release.nginx-ingress]

  name       = "promstack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  values     = [file("prom-stack-values.yml")]

  set = [
    {
      name  = "grafana.enabled"
      value = false
    },
    {
      name  = "prometheus.ingress.enabled"
      value = true
    },
    {
      name  = "prometheus.ingress.ingressClassName"
      value = "nginx"
    }
  ]
    set_list= [
    {
      name  = "prometheus.ingress.hosts"
      value = ["prometheus-${var.env}.rdevopsb87.online"]
    },
  ]

}

resource "helm_release" "nginx-ingress" {

  depends_on = [null_resource.kubeconfig]

  name       = "nginx-ingress"
  repository = "https://helm.nginx.com/stable"
  chart      = "nginx-ingress"
  values     = [file("ingress.yml")]

  set = [
    {
      name  = "controller.metrics.enabled"
      value = true
    },
    {
      name  = "controller.podAnnotations.prometheus\\.io/port"
      value = 10254
    },
    {
      name  = "controller.podAnnotations.prometheus\\.io/scrape"
      value = true
    },
  ]

}

resource "helm_release" "filebeat" {

  depends_on = [null_resource.kubeconfig]

  name       = "filebeat"
  repository = "https://helm.elastic.co"
  chart      = "filebeat"
  namespace  = "kube-system"

  values = [file("filebeat.yml")]

}

# Cluster Autoscaler
resource "helm_release" "cluster-autoscaler" {
  depends_on       = [null_resource.kubeconfig, aws_eks_pod_identity_association.cluster-autoscaler]
  name             = "cluster-autoscaler"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  namespace        = "default"
  create_namespace = true

  set = [
    {
      name  = "autoDiscovery.clusterName"
      value = var.env
    },
    {
      name  = "awsRegion"
      value = "us-east-1"
    }
  ]
}





## ISTIO
resource "helm_release" "istio-base" {
  depends_on = [
    null_resource.kubeconfig
  ]

  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = "istio-system"
  create_namespace = true
}

resource "helm_release" "istiod" {
  depends_on = [
    null_resource.kubeconfig,
    helm_release.istio-base
  ]

  name             = "istiod"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  namespace        = "istio-system"
  create_namespace = true
  version = "1.25"
}

resource "null_resource" "kiali" {
  depends_on = [
    null_resource.kubeconfig,
    helm_release.istiod
  ]
  provisioner "local-exec" {
    command = <<EOF
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.26/samples/addons/kiali.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.26/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.26/samples/addons/grafana.yaml
kubectl apply -f - <<EOK
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: HTTP
    nginx.ingress.kubernetes.io/secure-backends: "false"
  name: kiali
  namespace: istio-system
spec:
  ingressClassName: nginx
  rules:
  - host: kiali-dev.rdevopsb83.online
    http:
      paths:
      - backend:
          service:
            name: kiali
            port:
              number: 20001
        path: /kiali
        pathType: Prefix
EOK
EOF
  }
}