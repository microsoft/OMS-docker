# create acr task for windows from ci_feature branch to create image in cidev repository
az acr task create -n createimagecifeaturedev -r containerinsightsprod -c https://github.com/Microsoft/OMS-docker.git --branch ci_feature --file Kubernetes/windows/acrWorkflows/acrwindowsdevnamespace.yaml --commit-trigger-enabled true --platform Windows/amd64 --git-access-token 00000000000000000000000000 --auth-mode Default --debug

# create acr task for windows from ci_feature_prod branch to create image in ciprod repository
az acr task create -n createimagecifeaturedev -r containerinsightsprod -c https://github.com/Microsoft/OMS-docker.git --branch ci_feature --file Kubernetes/windows/acrWorkflows/acrwindowsprodnamespace.yaml.yaml --commit-trigger-enabled true --platform Windows/amd64 --git-access-token 00000000000000000000000000 --auth-mode Default --debug


# test task
az acr task update -n createimagewintestcidev -r containerinsightsprod -c https://github.com/Microsoft/OMS-docker.git --branch dilipr/winakslog --file Kubernetes/windows/acrWorkflows/acrwindowsdevnamespace.yaml --commit-trigger-enabled true --platform Windows/amd64 --git-access-token 00000000000000000000000000  --auth-mode Default --debug