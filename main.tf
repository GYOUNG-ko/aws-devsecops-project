terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

# 아틀란티스가 새로 생성해 볼 테스트용 네임스페이스
resource "kubernetes_namespace" "atlantis_demo" {
  metadata {
    name = "atlantis-gitops-demo"
  }
}

# 테스트용 컨피그맵
resource "kubernetes_config_map" "demo_config" {
  metadata {
    name      = "demo-config"
    namespace = kubernetes_namespace.atlantis_demo.metadata[0].name
  }

  data = {
    "message" = "Hello Atlantis GitOps!"
  }
}
