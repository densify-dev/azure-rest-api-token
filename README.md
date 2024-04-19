# azure-rest-api-token

The docker image produced from this repository - `densify/azure-rest-api-token` - allows you to obtain an HTTP Authorization Bearer token for a Microsoft Entra Service Principal (application client) to use for calling Azure REST API.

This container is typically used as a Kubernetes init container, and should be configured to write the token file to an `emptyDir` Kubernetes volume. The main container, requiring the token, can then read the token from the file on the volume. Ideally we would have used a Kubernetes secret for that purpose, however secrets are mounted read-only by the pods and are therefore not writable. Writing to a secret requires calling the Kubernetes API and having elevated access rights to do so. The risk of using an emptyDir volume is minimal, as it is permanently deleted with the pod. On top of that, by default the Bearer tokens returned by Microsoft are valid for 1 hour only.

See example [here](https://github.com/densify-dev/container-data-collection/tree/main/multi-cluster/examples/azmp).

## Prerequisites

The container requires three mandatory **environment variables**.

### ENTRA_SERVICE_PRINCIPAL

The value of this variable should be the path of a JSON file with the Entra service principle details. The file is typically made available to the container as a Kubernetes secret. See instructions [here](https://github.com/densify-dev/container-data-collection/tree/main/multi-cluster/examples/azmp) about how to register the Entra app and generate the secret.

The contents of this JSON file look like:

```json
{
	"appId": "<app id>",
	"displayName": "<app display name>",
	"password": "<client secret>",
	"tenant": "<tenant>"
}
```

All attributes of the JSON files are mandatory.

### BEARER_TOKEN_FILE

The value of this variable should be the path of the token file to write. If the file exists already, the container fails. Obviously, the container should have the permissions to create and write to this file. In the init container use-case, this file should reside on the `emptyDir` Kubernetes volume to make any sense (if it is on the ephemeral filesystem of the container, the main container won't be able to access it).

### AZURE_RESOURCE

The value of this variable should be the Azure resource for which the Entra app asks for a token, e.g. `https://prometheus.monitor.azure.com`. Obviously, the app should have the appropriate Azure IAM role assignment to access the resource, see [above example](https://github.com/densify-dev/container-data-collection/tree/main/multi-cluster/examples/azmp).

## Run

The container exits successfully (return code 0) if and only if it managed to get a token for the Entra app and the Azure resource and write it to the file. In any other case, it logs to the standard output the reason for failure and exits with a non-zero return code.
