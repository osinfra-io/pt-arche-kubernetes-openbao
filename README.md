# Kubernetes OpenBao OpenTofu Module

[![OpenTofu Tests](https://img.shields.io/github/actions/workflow/status/osinfra-io/pt-arche-kubernetes-openbao/test.yml?style=for-the-badge&logo=opentofu&color=FEDA15&label=OpenTofu%20Tests)](https://github.com/osinfra-io/pt-arche-kubernetes-openbao/actions/workflows/test.yml) [![Dependabot](https://img.shields.io/github/actions/workflow/status/osinfra-io/pt-arche-kubernetes-openbao/dependabot.yml?style=for-the-badge&logo=github&color=2088FF&label=Dependabot)](https://github.com/osinfra-io/pt-arche-kubernetes-openbao/actions/workflows/dependabot.yml) [![Datadog Security Enabled](https://img.shields.io/badge/Datadog%20Security-Enabled-632CA6?style=for-the-badge&logo=datadog)](https://app.datadoghq.com/security/code-security/repositories?repository_id=pt-arche-kubernetes-openbao)

## Repository Description

Reusable OpenTofu child module that deploys [OpenBao](https://openbao.org/) on GKE with the official Helm chart: high-availability Raft storage, the agent injector, audit storage, and optional pod anti-affinity. The service type and annotations are inputs, so cloud-specific exposure (GKE Ingress, DNS, certificates, multi-cluster ingress) stays in the consuming root.

## 🔩 Usage

Create the namespace in the consuming root (label it `istio.io/dataplane-mode=ambient` for the mesh) and pass its name to `//regional`. The module does not create namespaces. `//regional/local` provides an optional Gateway API `HTTPRoute` for local testing. The repository root is not a consumable module.

> [!TIP]
> You can check the [tests/fixtures](tests/fixtures) directory for example configurations. These fixtures set up the system for testing by providing all the necessary initial code, thus creating good examples on which to base your configurations.

## 🛠️ Tools

- [Helm](https://github.com/helm/helm)
- [OpenBao](https://openbao.org/docs/)
- [osinfra-pre-commit-hooks](https://github.com/osinfra-io/pt-techne-pre-commit-hooks)
- [pre-commit](https://github.com/pre-commit/pre-commit)

## 📋 Skills and Knowledge

Links to documentation and other resources required to develop and iterate in this repository successfully.

- [OpenBao Helm chart](https://github.com/openbao/openbao-helm)
- [OpenBao documentation](https://openbao.org/docs/)

## 🔍 Tests

All OpenTofu tests are [mocked](https://opentofu.org/docs/cli/commands/test/#the-mock_provider-blocks) allowing us to test the module without creating infrastructure or requiring credentials. The trade-offs are acceptable in favor of speed and simplicity. In an OpenTofu test, a mocked provider or resource will generate fake data for all computed attributes that would normally be provided by the underlying provider APIs.

```none
tofu init
tofu test
```

### Local integration testing

Run this command in Copilot CLI with the [`platform-grouping` plugin](https://github.com/osinfra-io/pt-ai-plugins/tree/main/plugins/platform-grouping) installed:

```text
/platform-grouping:test-local-integration
```

The local fixture initializes and unseals a single-replica OpenBao and saves the root token and unseal key in the ignored `tests/kubernetes/.work/` directory. It is reachable at `https://openbao.localhost`.

## 📦 Release

Push a semantic version tag after tests pass:

```none
git tag vX.Y.Z
git push origin vX.Y.Z
```
