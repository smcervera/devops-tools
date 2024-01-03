terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.24.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.12.1"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"  # Ruta al archivo de configuración de Kubernetes para Docker Desktop
  config_context = "docker-desktop"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "kubernetes_persistent_volume" "jenkins_pv_local" {
  metadata {
    name      = "jenkins-pv-local"
    namespace = "jenkins"
  }

  spec {
    storage_class_name = "jenkins-pv-local"
    access_modes       = ["ReadWriteOnce"]
    capacity {
      storage = "11Gi"
    }
    persistent_volume_reclaim_policy = "Retain"
    host_path {
      path = "/data/jenkins-volume/"
    }
  }
}

resource "kubernetes_storage_class" "jenkins_pv_local" {
  metadata {
    name = "jenkins-pv-local"
  }

  provisioner           = "kubernetes.io/no-provisioner"
  volume_binding_mode   = "WaitForFirstConsumer"
}

resource "helm_release" "argocd" {
  chart            = "argo-cd"
  name             = "argocd"
  namespace        = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  create_namespace = true
}

resource "helm_release" "argocd-apps" {
  depends_on = [helm_release.argocd]
  chart      = "argocd-apps"
  name       = "argocd-apps"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"

  values = [
    file("argocd/repositories.yaml"),
    file("argocd/applications.yaml")
  ]
}