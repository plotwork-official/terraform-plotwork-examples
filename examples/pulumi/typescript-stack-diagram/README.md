# Draw a Pulumi stack's outputs

A TypeScript Pulumi program that builds a diagram from the stack's own outputs and publishes it with the Plotwork provider, bridged from Terraform by Pulumi's Any Terraform Provider. The diagram is published again whenever an output it reads changes. With `bucket` set, the same source is rendered to an SVG and written to S3.

| | |
|---|---|
| Blocks | `plotwork.Diagram`, `plotwork.getRenderOutput`, `aws.s3.BucketObjectv2` |
| Plan | Every plan to publish; Pro to render to S3 |
| Cloud account | None, unless `bucket` is set: `pulumi.output({...})` stands in for the real stack |
| Needs | Pulumi 3.147.0 or later, Node.js 20 or later |

```shell
pulumi login --local                       # or your own backend
pulumi install                             # generates sdks/plotwork, then runs npm install
pulumi stack init dev
pulumi config set --secret plotwork:apiKey pw_...
pulumi up
pulumi config set replicas 4 && pulumi up  # the picture changes, the stable link does not
```

| Config | Effect |
|---|---|
| `plotwork:apiKey` (secret) | The API key. `PLOTWORK_API_KEY` works too, but stack config keeps it for `pulumi destroy` |
| `plotwork:apiUrl` | The API's address. Left out, `0.1.0-beta.2` talks to `https://api-preview.plotwork.dev` |
| `organization` | Publish to this organisation's private library instead of your own |
| `bucket` | Also render the SVG and write it to this S3 bucket (needs AWS credentials) |
| `replicas`, `environment` | Values the stand-in stack reports |

`link` is the stable link of a personal diagram, or the portal page of an organisation's diagram. Read links from `url`, `stableUrl` and `viewUrl`, not from the resource's `id`: Pulumi keeps the id of the first publish, while each change to the source publishes a new diagram.

`Pulumi.yaml` pins the provider with its full registry address, `registry.terraform.io/plotwork-official/plotwork`. The short form `plotwork-official/plotwork` looks in the OpenTofu registry, which does not carry the provider.

In your own program, replace the `deployment` stand-in with your resources' outputs, and edit the lines in `index.ts`. The [Plotwork language guide](https://docs.plotwork.dev/writing-diagrams) describes the syntax, and the [Pulumi guide](https://docs.plotwork.dev/pulumi) has the same program in Python.
