package kubernetes.tests

import data.kubernetes.policy as policy
import data.kubernetes.security as security

good_deploy := {
	"apiVersion": "apps/v1",
	"kind": "Deployment",
	"metadata": {
		"name": "demo-app",
		"namespace": "demo",
		"labels": {
			"app.kubernetes.io/name": "demo-app",
			"app.kubernetes.io/instance": "demo-app",
			"app.kubernetes.io/part-of": "demo",
			"environment": "dev",
			"owner": "platform",
		},
	},
	"spec": {"template": {
		"metadata": {"labels": {"app": "demo-app"}},
		"spec": {"containers": [{
			"name": "app",
			"image": "example.com/demo:1",
			"resources": {
				"requests": {
					"cpu": "100m",
					"memory": "128Mi",
				},
				"limits": {
					"cpu": "500m",
					"memory": "256Mi",
				},
			},
			"livenessProbe": {"httpGet": {
				"path": "/healthz",
				"port": 8080,
			}},
			"readinessProbe": {"httpGet": {
				"path": "/ready",
				"port": 8080,
			}},
			"securityContext": {
				"runAsNonRoot": true,
				"privileged": false,
				"capabilities": {"drop": ["ALL"]},
			},
		}]},
	}},
}

bad_service := {
	"apiVersion": "v1",
	"kind": "Service",
	"metadata": {
		"name": "public-service",
		"namespace": "demo",
		"labels": {
			"app.kubernetes.io/name": "public-service",
			"app.kubernetes.io/instance": "public-service",
			"app.kubernetes.io/part-of": "demo",
			"environment": "dev",
			"owner": "platform",
		},
	},
	"spec": {
		"type": "LoadBalancer",
		"ports": [{
			"port": 80,
			"targetPort": 8080,
		}],
		"selector": {"app": "demo-app"},
	},
}

test_deployment_passes if {
	count(policy.deny) == 0 with input as good_deploy
	count(security.deny) == 0 with input as good_deploy
}

test_service_fails if {
	count(policy.deny) > 0 with input as bad_service
	count(security.deny) == 0 with input as bad_service
}
